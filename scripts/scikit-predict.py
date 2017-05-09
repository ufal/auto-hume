#!/usr/bin/env python

import sys, argparse
import codecs
import model
import numpy as np
from sklearn.feature_extraction import DictVectorizer
from sklearn.preprocessing import LabelEncoder
from sklearn import cross_validation
from sklearn.cross_validation import train_test_split
from sklearn.cross_validation import KFold

# Parse command line arguments
parser = argparse.ArgumentParser(description="Train and crossvalidate Scikit-Learn model.")
parser.add_argument('--input_file', metavar='input_features', type=str)
parser.add_argument('--load_model', metavar='model_save_destination', nargs='?', type=str)
args = parser.parse_args()

data_X = []
data_Y = []

num_feat = 0

with codecs.open(args.input_file, 'rb', 'utf-8') as input_file:
    for line in input_file:
        feat_values = line.split("\t")
        feat_row = []
        if num_feat == 0:
            num_feat = len(feat_values)
        elif num_feat != len(feat_values):
            print "Error: Different number of features"
            sys.exit(1)
        data_X.append(feat_values)

Xtr = np.array(data_X, dtype=float)

# Load model, predict targets and exit
if args.load_model != None:
    m = model.loadModel(args.load_model)
    res = m.model.predict(Xtr)
    for r in res:
        print r
    sys.exit()
