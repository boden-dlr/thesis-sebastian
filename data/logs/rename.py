import os, time, datetime

from os import walk, path

path = "data/logs"

for (dirpath, dirnames, filenames) in os.walk(path):
    print(dirpath, dirnames, filenames)
    break

for filename in filenames:
    file = dirpath + os.sep + filename
    if file.endswith(".log"):
        with open(file) as f:
            lines = sum(1 for line in f)
        modified = os.path.getmtime(file)
        dt = datetime.datetime.fromtimestamp(
            time.mktime(time.localtime(modified)))
        prefix = dt.strftime("%Y-%m-%d_%H-%M-%S")
        print(prefix)
        os.rename(file, dirpath + os.sep + prefix + "_" + str(lines) + ".log")
