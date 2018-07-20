# 
# http://scikit-learn.org/stable/modules/clustering.html#clustering-performance-evaluation
# 
using PyCall

@pyimport sklearn

const metrics = sklearn.metrics

labels_true = [0, 0, 0, 1, 1, 1]
labels_pred = [0, 0, 1, 1, 2, 2]

metrics[:adjusted_rand_score](labels_true, labels_pred)
