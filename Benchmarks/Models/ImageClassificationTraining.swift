// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import TensorFlow
import Datasets

struct ImageClassificationTraining<Model, ClassificationDataset>
where Model: ImageClassificationModel, Model.TangentVector.VectorSpaceScalar == Float,
    ClassificationDataset: ImageClassificationDataset
{
    // TODO: (https://github.com/tensorflow/swift-models/issues/206) Datasets should have a common
    // interface to allow for them to be interchangeable in these benchmark cases.
    let dataset: ClassificationDataset
    let epochs: Int
    let batchSize: Int

    init(epochs: Int, batchSize: Int) {
        self.epochs = epochs
        self.batchSize = batchSize
        self.dataset = ClassificationDataset()
    }

    func train() {
        var model = Model()
        // TODO: Split out the optimizer as a separate specification.
        let optimizer = SGD(for: model, learningRate: 0.1)

        Context.local.learningPhase = .training
        for epoch in 1...epochs {
            let trainingShuffled = dataset.trainingDataset.shuffled(
                sampleCount: dataset.trainingExampleCount, randomSeed: Int64(epoch))
            for batch in trainingShuffled.batched(batchSize) {
                let (labels, images) = (batch.label, batch.data)
                let 𝛁model = model.gradient { model -> Tensor<Float> in
                    let logits = model(images)
                    return softmaxCrossEntropy(logits: logits, labels: labels)
                }
                optimizer.update(&model, along: 𝛁model)
            }
        }
    }
}
