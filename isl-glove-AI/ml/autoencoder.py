import tensorflow as tf

def build_autoencoder(timesteps, features):

    inputs = tf.keras.Input(shape=(timesteps, features))

    x = tf.keras.layers.Flatten()(inputs)
    x = tf.keras.layers.Dense(64, activation='relu')(x)
    encoded = tf.keras.layers.Dense(32, activation='relu')(x)

    x = tf.keras.layers.Dense(64, activation='relu')(encoded)
    x = tf.keras.layers.Dense(timesteps * features, activation='linear')(x)
    outputs = tf.keras.layers.Reshape((timesteps, features))(x)

    autoencoder = tf.keras.Model(inputs, outputs)

    encoder = tf.keras.Model(inputs, encoded)

    autoencoder.compile(optimizer='adam', loss='mse')

    return autoencoder, encoder
