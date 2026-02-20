import tensorflow as tf

ALPHABET_LABELS = [chr(code) for code in range(ord("A"), ord("Z") + 1)]


def build_classifier(input_shape, num_classes=len(ALPHABET_LABELS)):

    inputs = tf.keras.Input(shape=input_shape)

    x = tf.keras.layers.Conv1D(32, 3, activation='relu')(inputs)
    x = tf.keras.layers.MaxPooling1D(2)(x)
    x = tf.keras.layers.GRU(32)(x)

    x = tf.keras.layers.Dense(16, activation='relu')(x)
    outputs = tf.keras.layers.Dense(num_classes, activation='softmax')(x)

    model = tf.keras.Model(inputs, outputs)

    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    return model
