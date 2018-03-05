using LogClustering.Log

# test with some dummy data
text = [
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
]

result = Log.split_overlapping(text, r"this text will never be found")
assert(result.prefix == result.suffix)
assert(length(result.prefix) == 6)
assert(length(result.suffix) == 6)

# test: find an ID by a given selector
text = [
    "prefix",
    "prefix",
    "prefix",
    string(randstring(), " Marker 'a' ", randstring()),
    string(randstring(), " Marker 'b' ", randstring()),
    string(randstring(), " Marker 'a' ", randstring()),
    string(randstring(), " Marker 'b' ", randstring()),
    string(randstring(), " Marker 'c' ", randstring()),
    string(randstring(), " Marker 'c' ", randstring()),
    "suffix",
    "suffix",
    "suffix",
]

result = Log.split_overlapping(text, r"Marker \'(.*?)\'")
expected = Dict(
    "a" => Log.Occurence(4,6,text[4:6]),
    "b" => Log.Occurence(5,7,text[5:7]),
    "c" => Log.Occurence(8,9,text[8:9]),
)
assert(result.splitted == expected)
assert(result.prefix == ["prefix","prefix","prefix"])
assert(result.suffix == ["suffix","suffix","suffix"])

# test with a log file
regex_workflow = r"Workflow \'(\S*?)\'"i

text = readlines("data/logs/2016-06-01_13-56-53_1273.log")
result = Log.split_overlapping(text, regex_workflow)
for key in keys(result.splitted)
    assert(key in String[
        "test_ssh_workflow_happycase_2016-06-01_13:11:43_01",
        "D:\\DELiS_tools\\RCE\\RCE_server_FrEACS_7.x\\workspace\\DC_SBW_FortpflanzungUnsicherheiten\\Test_Workflow\\WF\\test_ssh_workflow_happycase.wf",
        "hap2_testworkflow_2016-06-01_13:30:54_04",
        "test_ssh_workflow_happycase_2016-06-01_13:41:42_03",
        "test_ssh_workflow_happycase_2016-06-01_13:56:41_04",
        "test_ssh_workflow_happycase_2016-06-01_13:26:42_02",
        "hap2_testworkflow_2016-06-01_13:36:06_05",
    ])
    assert(length(result.splitted[key].content) in [94,490,89,40,37,55,86,])
end
assert(length(result.prefix) == 725)
assert(length(result.suffix) == 19)

# test with a big log file
text = readlines("data/logs/2018-01-31_13-15-07_70734.log")
result = Log.split_overlapping(text, regex_workflow)
for key in keys(result.splitted)
    assert(key in ["MDO_CO_Sellar_2018-01-31_12:51:00_01"])
    assert(length(result.splitted[key].content) in [69924])
end
assert(length(result.prefix) == 754)
assert(length(result.suffix) == 56)

text = readlines("data/logs/2018-03-01_15-11-18_51750.log")
result = Log.split_overlapping(text, regex_workflow)
for key in keys(result.splitted)
    assert(key in [
        "Test12-01_2016-01-20_17:34:26_15",
        "TestFsmsLoop_2016-01-28_10:38:35_11",
        "Test12-01_2016-01-19_15:04:15_03",
        "Test21-01_2016-01-22_11:18:28_03",
        "TestFsmsLoop_2016-01-28_09:20:57_01",
        "Test12-01_2016-01-14_16:59:51_10",
        "Test21-01_2016-01-21_10:56:29_04",
        "Test12-01_2016-01-19_16:44:43_09",
        "TestFsmsLoop3_2016-01-28_13:47:45_11",
        "TestFsmsLoop_2016-01-29_09:20:11_01",
        "Test12-01_2016-01-19_15:26:34_06",
        "Test12-01_2016-01-14_13:11:38_01",
        "TestFSMS_2016-01-14_16:41:54_02",
        "Test12-01_2016-01-20_17:32:59_14",
        "Test_2016-01-22_13:42:03_06",
        "TestFsmsLoop3_2016-01-28_11:18:31_19",
        "Test12-01_2016-01-20_17:28:54_10",
        "Test21-01_2016-01-22_11:58:30_01",
        "Test21-01_2016-01-22_13:30:17_04",
        "TestFsmsLoop1_2016-01-28_11:52:32_22",
        "Test_2016-01-22_13:40:33_05",
        "TestFsmsLoop_2016-01-28_10:11:13_08",
        "Test12-01_2016-01-19_14:10:37_10",
        "Test12-01_2016-01-14_16:26:14_07",
        "Test12-01_2016-01-18_10:21:41_03",
        "Test21-01_2016-01-22_11:14:34_02",
        "Test21-01_2016-01-21_16:20:53_01",
        "TestFsmsLoop_2016-01-28_09:48:54_04",
        "TestFsmsLoop3_2016-01-28_12:16:30_25",
        "TestFsmsLoop_2016-01-28_16:03:26_01",
        "Test12-01_2016-01-14_17:00:37_11",
        "Test12-01_2016-01-15_09:47:41_07",
        "Test12-01_2016-01-18_10:12:20_02",
        "Test12-01_2016-01-20_16:14:48_06",
        "TestFsmsLoop3_2016-01-28_15:06:55_01",
        "Test12-01_2016-01-15_11:59:16_09",
        "Test12-01_2016-01-15_13:12:51_10",
        "Test12-01_2016-01-19_10:16:52_01",
        "Test12-01_2016-01-20_17:30:54_12",
        "Test12-01_2016-01-19_13:40:17_05",
        "Test21-01_2016-01-21_11:16:01_07",
        "Test12-01_2016-01-19_14:32:55_01",
        "Test_2016-01-15_09:37:20_03",
        "TestFsmsLoop1_2016-01-28_12:08:42_24",
        "TestFsmsLoop3_2016-01-28_14:58:07_03",
        "Test12-01_2016-01-14_14:00:10_04",
        "Test_2016-01-15_09:41:09_06",
        "Test12-01_2016-01-14_16:32:25_10",
        "Test21-01_2016-01-25_15:56:57_01",
        "Test12-01_2016-01-20_09:14:56_01",
        "Test21-01_2016-01-22_11:27:38_02",
        "TestFsmsLoop1_2016-01-28_11:11:44_16",
        "TestFsmsLoop1_2016-01-28_10:48:38_14",
        "TestFsmsLoop1_2016-01-28_10:46:23_13",
        "TestFsmsLoop3_2016-01-28_12:28:40_01",
        "Test12-01_2016-01-19_13:16:38_04",
        "Test12-01_2016-01-19_15:07:45_04",
        "Test12-01_2016-01-20_17:31:02_13",
        "Test_2016-01-15_09:38:43_04",
        "Test_2016-01-21_16:53:58_02",
        "TestFsmsLoop_2016-01-28_09:42:40_03",
        "TestFsmsLoop1_2016-01-28_13:06:32_08",
        "Test12-01_2016-01-18_16:56:36_06",
        "Test12-01_2016-01-14_16:05:49_06",
        "Test_2016-01-18_17:03:09_07",
        "Test_2016-01-18_17:11:56_12",
        "TestFsmsLoop1_2016-01-28_11:13:56_17",
        "Test12-01_2016-01-20_11:08:22_03",
        "Test21-01_2016-01-22_13:46:50_07",
        "Test21-01_2016-01-21_10:52:17_03",
        "Test21-01_2016-01-22_11:25:47_01",
        "TestFsmsLoop3_2016-01-28_14:03:55_13",
        "Test21-01_2016-01-21_10:43:50_02",
        "Test_2016-01-18_17:07:15_11",
        "TestFsmsLoop_2016-01-28_10:03:13_07",
        "Test21-01_2016-01-22_11:41:49_03",
        "Test_2016-01-25_16:16:48_02",
        "TestFsmsLoop_2016-02-01_09:16:43_01",
        "Test12-01_2016-01-20_16:16:24_07",
        "Test21-01_2016-01-21_09:53:51_01",
        "Test_2016-01-22_12:13:06_02",
        "TestFsmsLoop1_2016-01-28_10:45:13_12",
        "TestFsmsLoop1_2016-01-28_13:00:35_06",
        "TestFsmsLoop_2016-01-28_13:48:03_12",
        "Test_2016-01-18_17:05:59_10",
        "TestFsmsLoop1_2016-01-28_11:18:13_18",
        "TestFsmsLoop_2016-01-28_11:22:07_20",
        "TestFsmsLoop1_2016-01-28_14:51:23_01",
        "Test_2016-01-15_10:22:03_08",
        "TestFsmsLoop_2016-01-28_11:44:08_21",
        "Test_2016-01-22_12:14:13_03",
        "TestFsmsLoop1_2016-01-28_12:54:33_05",
        "Test12-01_2016-01-20_11:36:52_04",
        "Test12-01_2016-01-20_17:20:12_09",
        "TestFsmsLoop3_2016-01-28_15:25:21_02",
        "Test21-01_2016-01-22_11:52:32_01",
        "Test12-01_2016-01-14_16:51:39_08",
        "Test12-01_2016-01-20_17:18:26_08",
        "Test12-01_2016-01-14_16:30:26_09",
        "TestFsmsLoop_2016-01-28_14:58:20_04",
        "Test_2016-01-25_16:37:24_04",
        "Test21-01_2016-01-22_13:57:49_08",
        "Test21-01_2016-01-22_11:43:34_01",
        "Test12-01_2016-01-14_15:48:48_05",
        "Test12-01_2016-01-19_14:03:44_09",
        "TestFsmsLoop_2016-01-28_09:32:08_02",
        "Test21-01_2016-01-22_14:01:52_09",
        "TestFsmsLoop1_2016-01-28_12:51:22_04",
        "TestFsmsLoop1_2016-01-28_13:26:56_10",
        "Test_2016-01-25_16:19:18_03",
        "Test12-01_2016-01-15_09:24:11_01",
        "Test12-01_2016-01-19_10:42:36_03",
        "Test12-01_2016-01-20_13:42:02_05",
        "Test12-01_2016-01-19_13:54:17_08",
        "TestFsmsLoop1_2016-01-28_14:55:09_02",
        "Test12-01_2016-01-19_13:49:54_07",
        "Test_2016-01-15_09:39:02_05",
        "Test_2016-01-18_17:04:23_09",
        "Test12-01_2016-01-14_13:40:09_02",
        "Test21-01_2016-01-26_14:08:01_01",
        "Test12-01_2016-01-15_09:31:42_02",
        "Test12-01_2016-01-18_09:13:04_01",
        "Test12-01_2016-01-19_10:30:03_02",
        "Test12-01_2016-01-20_09:28:05_02",
        "TestFsmsLoop_2016-01-28_10:29:27_10",
        "TestFsmsLoop1_2016-01-28_10:58:45_15",
        "Test12-01_2016-01-18_17:27:36_14",
        "Test_2016-01-26_17:28:56_02",
        "Test12-01_2016-01-14_16:39:46_01",
        "Test21-01_2016-01-21_11:01:31_06",
        "TestFsmsLoop_2016-01-28_09:57:27_05",
        "Test12-01_2016-01-15_13:26:06_11",
        "Test_2016-01-25_16:47:54_05",
        "Test12-01_2016-01-20_17:29:12_11",
        "Test12-01_2016-01-18_16:37:00_05",
        "Test12-01_2016-01-14_13:55:54_03",
        "Test12-01_2016-01-18_16:35:13_04",
        "Test12-01_2016-01-14_16:44:24_03",
        "Test12-01_2016-01-19_16:37:04_08",
        "Test21-01_2016-01-27_09:07:04_01",
        "Test12-01_2016-01-19_15:41:01_07",
        "Test21-01_2016-01-22_11:12:14_01",
        "TestFsmsLoop1_2016-01-28_13:03:49_07",
        "testFSMSLoopConverger_2016-01-29_14:20:25_02",
        "Test_2016-01-22_14:05:57_10",
        "Test12-01_2016-01-19_13:41:28_06",
        "TestFsmsLoop_2016-01-28_15:42:24_03",
        "Test12-01_2016-01-19_14:45:40_02",
        "Test17-12_1_2016-01-14_16:53:41_09",
        "Test12-01_2016-01-14_16:28:33_08",
        "Test12-01_2016-01-19_16:52:36_10",
        "Test21-01_2016-01-21_10:59:13_05",
        "TestFsmsLoop_2016-01-28_10:22:16_09",
        "TestFsmsLoop1_2016-01-28_12:35:07_03",
        "TestFsmsLoop3_2016-01-28_12:32:16_02",
        "TestFsmsLoop1_2016-01-28_13:09:41_09",
    ])

    assert(length(result.splitted[key].content) in [
        123,39,82,106,344,69,236,129,18209,1332,115,181,83,50,39,67,50,
        137,118,66,39,54,115,55,67,141,130,61,362,624,68,68,67,51,531,
        67,81,129,72,67,115,67,38,54,344,257,52,68,129,130,105,55,39,41,
        177,129,117,57,8,39,55,62,67,116,42,28,54,279,116,165,175,168,
        115,28,90,206,46,52,337,121,39,36,69,197,28,123,133,335,28,293,
        39,104,377,51,378,239,68,617,68,383,39,151,116,116,130,64,171,
        46,18335,39,67,115,337,67,372,67,38,28,178,115,68,67,129,340,54,
        54,48,39,67,132,157,67,39,51,115,155,67,35,117,115,115,168,55,
        1600,42,115,370,67,123,67,337,236,155,109,73,128])
end
assert(length(result.prefix) == 856)
assert(length(result.suffix) == 0)
