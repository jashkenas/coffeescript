var dates, sentence, sep;
sentence = ("" + (22 / 7) + " is a decent approximation of π");
sep = "[.\\/\\- ]";
dates = (new RegExp("\\d+" + (sep) + "\\d+" + (sep) + "\\d+", "g"));