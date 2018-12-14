#!/home/site/env2/bin/python
# -*- coding: UTF-8 -*-

# enable debugging
import cgi

import cgitb
cgitb.enable()

import sys
# import knnimpute
import inspect
import pandas as pd
import numpy as np
import numpy.ma as ma
import array
import scipy
from firebase import firebase
from scipy.interpolate import griddata
import scipy.interpolate
import json
import matplotlib.pyplot as plt
import pyKriging
from pyKriging.krige import kriging
from pyKriging.samplingplan import samplingplan


print "Content-Type: text/plain;charset=utf-8"
print

# print scipy.version.version
# print np.version.version

bound1_lat = 0
bound2_lat = 10
bound1_lon = 0
bound2_lon = 10
latitudes = []
longitudes = []
values = []

firebase = firebase.FirebaseApplication('https://mustny-56e31.firebaseio.com/', None)
subres = firebase.get('/PhillyTest01/data', None)

arguments = cgi.FieldStorage()
# print arguments.keys()
for i in arguments.keys():
  if i == 'bound1_lat':
    bound1_lat = float(arguments[i].value)
  elif i == 'bound2_lat':
    bound2_lat = float(arguments[i].value)
  elif i == 'bound1_lon':
    bound1_lon = float(arguments[i].value)
  elif i == 'bound2_lon':
    bound2_lon = float(arguments[i].value)
  # elif i == 'lat':
  #   latitudes  = json.loads(arguments[i].value)
  # elif i == 'lon':
  #   longitudes = json.loads(arguments[i].value)
  # elif i == 't':
  #   values = json.loads(arguments[i].value)

var = 'Te'
latitudes = []
longitudes = []
values = []
temp = []
hum = []
P10 = []
P1 = []
P25 = []
S2A = []
S2W = []
S3A = []
S3W = []

for key in subres.keys():
  if (subres[key]['lat'] != '0' and subres[key]['lng'] != '0' and subres[key][var] != '0'):
      if (subres[key]['lat'] != '' and subres[key]['lng'] != '' and subres[key][var] != ''):
        latitudes.append(subres[key]['lat'])
        longitudes.append(subres[key]['lng'])
        values.append(subres[key][var])
        temp.append(subres[key]['Te'])
        hum.append(subres[key]['Hu'])
        P10.append(subres[key]['P10'])
        P25.append(subres[key]['P25'])
        S2A.append(subres[key]['S2A'])
        S2W.append(subres[key]['S2W'])
        S3A.append(subres[key]['S3A'])
        S3W.append(subres[key]['S3W'])
        P1.append(subres[key]['P1'])

latitudes = [float(i) for i in latitudes if i]
longitudes = [float(i) for i in longitudes if i]
values = [float(i) for i in values if i]
temp = [float(i) for i in temp if i]
hum = [float(i) for i in hum if i]
P10 = [float(i) for i in P10 if i]
P1 = [float(i) for i in P1 if i]
P25 = [float(i) for i in P25 if i]
S2A = [float(i) for i in S2A if i]
S2W = [float(i) for i in S2W if i]
S3A = [float(i) for i in S3A if i]
S3W = [float(i) for i in S3W if i]

bound1_lat = min(latitudes)
bound2_lat = max(latitudes)
bound1_lon = min(longitudes)
bound2_lon = max(longitudes)

filter_box_lat = []
filter_box_lon = []
filter_box_values = []
filter_box_temp = []
filter_box_hum = []
filter_box_P10 = []
filter_box_P1 = []
filter_box_P25 = []
filter_box_S2A = []
filter_box_S2W = []
filter_box_S3A = []
filter_box_S3W = []

def reject_outliers(data, m = 3):
    mean = np.mean(data)
    std = np.std(data)
    for i in range(0, len(data)):
      if abs(data[i] - mean) > m * std:
        if i == 0:
          data[i] = data[i+1]
        else:
          data[i] = data[i-1]
    return data

def nan_helper(data):

  A = np.array(data)
  A = ma.masked_array(A)

  for shift in (-1,1):
    for axis in (0,1):
        a_shifted = np.roll(A, shift = shift, axis = axis)
        idx = ~a_shifted.mask * A.mask
        A[idx] = a_shifted[idx]

  # A = np.array(data)
  # ind = np.where(~np.isnan(A))[0]
  # first, last = ind[0], ind[-1]
  # A[:first] = A[first]
  # A[last + 1:] = A[last]
  # print(A.tolist())
  return A

# remove the outliers
values = reject_outliers(np.array(values))
temp = reject_outliers(temp)
hum = reject_outliers(hum)
P10 = reject_outliers(P10)
P1 = reject_outliers(P1)
P25 = reject_outliers(P25)
S2A = reject_outliers(S2A)
S2W = reject_outliers(S2W)
S3A = reject_outliers(S3A)
S3W = reject_outliers(S3W)

for i in range(0, len(latitudes)):
      if (latitudes[i] <= bound2_lat) and (latitudes[i] >= bound1_lat) and (longitudes[i] <= bound2_lon) and (longitudes[i] >= bound1_lon):
          filter_box_lat.append(latitudes[i])
          filter_box_lon.append(longitudes[i])
          filter_box_values.append(values[i])
          filter_box_temp.append(temp[i])
          filter_box_hum.append(hum[i])
          filter_box_P1.append(P1[i])
          filter_box_P10.append(P10[i])
          filter_box_P25.append(P25[i])
          filter_box_S2A.append(S2A[i])
          filter_box_S2W.append(S2W[i])
          filter_box_S3A.append(S3A[i])
          filter_box_S3W.append(S3W[i])

grid_x, grid_y = np.mgrid[bound1_lon:bound2_lon:80j, bound1_lat:bound2_lat:80j]
points = np.vstack((filter_box_lon, filter_box_lat)).T
mean = np.mean(filter_box_values)
# , fill_value=mean
grid_z0 = griddata(points, filter_box_values, (grid_x, grid_y), method = 'linear')
grid_z_temp = griddata(points, filter_box_temp, (grid_x, grid_y), method = 'linear', fill_value = np.mean(filter_box_temp))
grid_z_hum = griddata(points, filter_box_hum, (grid_x, grid_y), method = 'linear', fill_value = np.mean(filter_box_hum))
grid_z_P1 = griddata(points, filter_box_P1, (grid_x, grid_y), method = 'linear')
grid_z_P10 = griddata(points, filter_box_P10, (grid_x, grid_y), method = 'linear')
grid_z_P25 = griddata(points, filter_box_P25, (grid_x, grid_y), method = 'linear', fill_value = np.mean(filter_box_P25))
grid_z_S2A = griddata(points, filter_box_S2A, (grid_x, grid_y), method = 'linear')
grid_z_S2W = griddata(points, filter_box_S2W, (grid_x, grid_y), method = 'linear')
grid_z_S3A = griddata(points, filter_box_S3A, (grid_x, grid_y), method = 'linear')
grid_z_S3W = griddata(points, filter_box_S3W, (grid_x, grid_y), method = 'linear')

# grid_z_temp = pd.DataFrame(grid_z_temp)
# grid_z_temp = grid_z_temp.interpolate(method='nearest')

#grid_z_temp = nan_helper(grid_z_temp)
# grid_z_hum = nan_helper(grid_z_hum)

# grid_z0.tolist()
original = {"lat": latitudes, "lon": longitudes, "temp": temp, "hum": hum, "P10": P10, "P1": P1, "P25": P25, "S2A": S2A, "S2W": S2W, "S3A": S3A, "S3W": S3W}
processed = {"temp": grid_z_temp.tolist(), "hum": grid_z_hum.tolist(), "P10": grid_z_P10.tolist(), "P1": grid_z_P1.tolist(), "P25": grid_z_P25.tolist(), "S2A": grid_z_S2A.tolist(), "S2W": grid_z_S2W.tolist(), "S3A": grid_z_S3A.tolist(), "S3W": grid_z_S3W.tolist()}
data = {"original": original, "processed": processed}

print "interpolate("
# print json.dumps(subres)
# print json.dumps(grid_z0.tolist())
print json.dumps(data)
print ")"

# plt.ion()
# plt.imshow(grid_z0.T, extent=(bound1_lon,bound2_lon,bound1_lat,bound2_lat), origin='lower')
# # plt.plot(points[:,0], points[:,1], 'k.', ms=1)
# plt.ylim(bound1_lat,bound2_lat)
# plt.xlim(bound1_lon,bound2_lon)
# plt.gcf().set_size_inches(10, 10)
# plt.axis('off')
# plt.savefig('TEMP_400x400.png')
# plt.savefig(subURL+'-'+var+'.png', bbox_inches='tight',pad_inches=-1)
