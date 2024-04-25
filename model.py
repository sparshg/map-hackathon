# %%
import tensorflow as tf
from tensorflow.keras import layers, models, regularizers
import pandas as pd
import numpy as np
import os

# %%


# %%
class DataGenerator(tf.keras.utils.Sequence):
    def __init__(self, path, batch_size=32):
        self.data_filenames = [
            os.path.join(path, filename) for filename in os.listdir(path)
        ]
        self.batch_size = batch_size

    def __len__(self):
        return len(self.data_filenames) // self.batch_size

    def __getitem__(self, index):
        batch_filenames = self.data_filenames[
            index * self.batch_size : (index + 1) * self.batch_size
        ]
        X, y = self.__data_generation(batch_filenames)
        return X, y

    def __data_generation(self, batch_filenames):
        X = []
        y = []
        for filename in batch_filenames:
            image = np.load(filename, allow_pickle=True).astype(np.float32)
            label = np.array([int(filename.split("_")[-1].split(".")[0])])
            X.append(image)
            y.append(label)

        return np.array(X), np.array(y)


# %%


def build_model():
    model = models.Sequential()
    model.add(
        layers.Conv2D(
            32,
            (3, 3),
            activation="relu",
            input_shape=(100, 6, 1),
            kernel_regularizer=regularizers.l2(0.0001),
            padding="same",
        )
    )
    model.add(layers.MaxPooling2D((2, 2)))
    model.add(layers.Dropout(0.3))
    model.add(
        layers.Conv2D(
            64,
            (3, 3),
            activation="relu",
            kernel_regularizer=regularizers.l2(0.0001),
            padding="same",
        )
    )
    model.add(layers.MaxPooling2D((2, 2)))
    model.add(layers.Dropout(0.3))
    model.add(layers.Flatten())
    model.add(layers.Dense(16, activation="relu"))
    model.add(layers.Dropout(0.5))
    model.add(layers.Dense(2, activation="sigmoid"))
    return model


def compile_model(model):
    model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    return model


def train_model(model, train_data_labels, epochs, batch_size):
    model.fit(train_data_labels, epochs=epochs, batch_size=batch_size)
    return model


def evaluate_model(model, test_data_labels):
    test_loss, test_acc = model.evaluate(test_data_labels)
    return test_loss, test_acc


def save_model(model, path):
    model.save(path)


def load_model(path):
    model = models.load_model(path)
    return model


def predict(model, data):
    return model.predict(data)


# %%
data = [pd.read_csv(f"files/usable{i}.csv") for i in [1, 2, 3]]
data = [
    d[
        [
            "user_accelerometer_x",
            "user_accelerometer_y",
            "user_accelerometer_z",
            "gyroscope_x",
            "gyroscope_y",
            "gyroscope_z",
            "pothole",
        ]
    ]
    for d in data
]
# print(np.concatenate([d.to_numpy() for d in data], axis=0).shape)
labels = pd.concat([d.pop("pothole") for d in data])
length = len(labels) - len(labels) % 100
labels = labels[:length]
data = np.concatenate([d.to_numpy() for d in data], axis=0)[:length]
print(data.shape)


def weighted_average(arr):
    """Calculate the weighted average of an array with Gaussian-like weights."""
    size = len(arr)
    sigma = size / 7  # Adjust sigma as needed
    x = np.linspace(-size / 2, size / 2, size)
    weights = np.exp(-0.5 * (x / sigma) ** 2)
    weights /= np.sum(weights)
    return np.sum(arr * weights)


for i in range(0, length - 100 + 25, 25):
    image = data[i : i + 100]
    image = image.reshape((100, 6, 1))
    label = 1 if weighted_average(labels[i : i + 100]) > 0.2 else 0
    print(image.shape, i // 25, label)
    np.save(f"concat/{i//25}_{label}.npy", image)
# %%

model = build_model()
model = compile_model(model)

train_data_labels = DataGenerator("concat", batch_size=32)
# test_data_labels = DataGenerator("test", batch_size=32)


model = train_model(model, train_data_labels, epochs=36, batch_size=32)
# test_loss, test_acc = evaluate_model(model, test_data_labels)
# print(f"Test accuracy: {test_acc}, Test loss: {test_loss}")
save_model(model, "model.h5")

# %%
model = load_model("model.h5")
input_data = np.load("test/14_1.npy", allow_pickle=True).astype(np.float32)
input_data = input_data.reshape((1, 100, 6, 1))
print(predict(model, input_data))

# %%

converter = tf.lite.TFLiteConverter.from_keras_model(
    load_model("model93-23.h5")
)  # path to the SavedModel directory
tflite_model = converter.convert()

# Save the model.
with open("model.tflite", "wb") as f:
    f.write(tflite_model)
# %%
