---
title: "Excel .XLSX is Just Text Files in a Trench Coat"
date: 2024-06-05 12:00:00 -0400
categories: [Technology, Data]
tags: [xml, excel, soap, file-formats, python]
---

# It's XML All the Way Down

I was forced to use XML to create a series of requests to an API that was only available in SOAP. Fortunately, there is a Python library called Zeep ([docs.python-zeep.org/](https://docs.python-zeep.org/)) – without it, I would have been completely lost. I grumbled through this task, feeling like I was working on something that if not destined to be obsolete was well on its way.

Only recently, I learned that XLSX files are actually zipped XML files. So let's take one apart:

### 1. Initial CSV File
Starting with a CSV file has about 1200 rows and 17 columns comes to 210 KB.

user/downloads/
└── data.csv (210 KB)


### 2. CSV Saved as .xlsx
Since the file is zipped, saving it as a .xlsx file reduces the file size to 141 KB.


user/downloads/
├── data.csv (210 KB)
└── data.xlsx (141 KB)


### 3. Formatted .xlsx File
Creating a formatted table and changing the fonts increases the size of the file to 768 KB.

user/downloads/
├── data.csv (210 KB)
└── data.xlsx (768 KB)



### 5. Now you can change the file extension to .zip and unzip the file to see the contents

user/downloads/
├── _rels/
│   └── .rels
├── docProps/
│   ├── app.xml
│   ├── core.xml
│   └── custom.xml        (optional)
├── xl/
│   ├── _rels/
│   │   └── workbook.xml.rels
│   ├── theme/
│   │   └── theme1.xml
│   ├── worksheets/
│   │   └── sheet1.xml
│   ├── styles.xml
│   ├── workbook.xml
│   └── sharedStrings.xml (optional)
├── [Content_Types].xml
├── data.csv (210 KB)
└── data.zip (approx. 768 KB)



Now the weird changes in file size and why some (relatively) small XLSX files take so long to open almost makes sense. When I heard it was the Microsoft standard since 2007, I instantly assumed it was some nefarious plot to consolidate their market share. But actually, it opened up Excel from a proprietary to an open format called [Office Open XML (OOXML)](https://en.wikipedia.org/wiki/Office_Open_XML). My bad Microsoft. I guess I should have read the [ISO/IEC 29500:2008](https://www.iso.org/standard/39574.html) standard before jumping to conclusions.

## A Brief History of XML

XML (eXtensible Markup Language) was created in the late 1990s to replace SGML which I am guessing was a replacement for something else.  So knowledge marches on.