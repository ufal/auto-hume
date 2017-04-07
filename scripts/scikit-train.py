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
parser.add_argument('--target_file', metavar='input_target', type=str)
parser.add_argument('--model_type', metavar='model_type', type=str)
parser.add_argument('--model_params', metavar='model_parameters', type=str)
parser.add_argument('--save_model', metavar='model_save_destination', nargs='?', type=str)
args = parser.parse_args()

model_type = args.model_type

data_X = []
data_Y = []

num_feat = 0
num_instances = 0

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
        num_instances += 1

with codecs.open(args.target_file, 'rb', 'utf-8') as target_file:
    for line in target_file:
        feat_values = line.split("\t")
        data_Y.append(feat_values[0])

if len(data_Y) != num_instances:
    print "Error: Different number of lines"
    sys.exit(1)

Xtr = np.array(data_X, dtype=float)
Ytr = np.array(data_Y, dtype=float)

m = model.Model(args.model_type, args.model_params)

# Train model and save it
if args.save_model != None:
    m.model.fit(Xtr, Ytr)
    model.saveModel(m, args.save_model)
