import tensorflow as tf

def build_classifier(input_shape, num_classes):

    inputs = tf.keras.Input(shape=input_shape)

    x = tf.keras.layers.Conv1D(32, 3, activation='relu')(inputs)
    x = tf.keras.layers.MaxPooling1D(2)(x)
    # Unroll GRU so conversion is less likely to emit dynamic TensorList ops.
    x = tf.keras.layers.GRU(32, unroll=True)(x)

    x = tf.keras.layers.Dense(16, activation='relu')(x)
    outputs = tf.keras.layers.Dense(num_classes, activation='softmax')(x)

    model = tf.keras.Model(inputs, outputs)

    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    return model
