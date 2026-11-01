# Third-party data

## JMdict

`src/contents/ui/lib/JMDictData.js` is generated from the Japanese-English
JMdict XML distribution:

https://www.edrdg.org/wiki/JMdict-EDICT_Dictionary_Project.html

JMdict is copyright the Electronic Dictionary Research and Development Group
(EDRDG). It is redistributed under the EDRDG General Dictionary Licence. The
generated file contains only Japanese headwords and their kana readings; the
English meanings and other metadata are not included.

The source data is updated regularly. To regenerate the bundled table, obtain
the current `JMdict_e` XML file and run:

```sh
python3 tools/gen-jmdict-data.py JMdict_e > src/contents/ui/lib/JMDictData.js
```

## UniDic-lite

`src/contents/ui/lib/UniDicData.js` is generated from the UniDic 2.1.2
`lex.csv` source used by UniDic-lite:

https://github.com/polm/unidic-lite

UniDic is developed by the UniDic Consortium and NINJAL and is distributed
under the modified BSD licence. Only common surface forms and their
pronunciations are retained in the generated file.
