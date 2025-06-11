# FP_SNPs Allele Converter

## Описание

Данный проект содержит скрипт `convert_alleles.py`, предназначенный для преобразования файла в формате:
#CHROM POS ID allele1 allele2
в формат, приближенный к формату VCF:
#CHROM POS ID REF ALT

Референсный аллель определяется с использованием последовательностей из **референсного генома человека** GRCh38.d1.vd1. Альтернативный аллель — это второй аллель, отличный от референсного.

Скрипт поддерживает:
- Проверку корректности входных данных,
- Логирование с временными метками,
- Поддержку аргументов командной строки в стиле `--ключ значение`,
- Отображение справки с помощью `--help`.

## Предварительная подготовка входного файла

Исходный файл: `FP_SNPs.txt`, скачанный из архива GRAF v2.4 с [официального сайта NCBI](https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/Software.cgi).

Файл содержит:
- идентификаторы SNP (`rs#`),
- координаты в референсах GRCh37 и GRCh38,
- аллели (`allele1`, `allele2`).
- 1000 SNP с X-хромосомы (в формате — хромосома 23), используемые для определения пола

### Цель преобразования:

Создать файл `FP_SNPs_10k_GB38_twoAllelsFormat.tsv` с колонками:

#CHROM POS ID allele1 allele2

## Шаги предподготовки (bash):

1. Удаление заголовка, удаление chr23 (X), отбор нужных колонок:
```bash
tail -n +2 FP_SNPs.txt \
| awk -F '\t' '{ if ($2 != "23") print "chr" $2 "\t" $4 "\trs" $1 "\t" $5 "\t" $6 }' \
> FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```
2. Добавление заголовка:

```bash
echo -e "#CHROM\tPOS\tID\tallele1\tallele2" | cat - FP_SNPs_10k_GB38_twoAllelsFormat.tsv > tmp && mv tmp FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```

## convert_alleles.py
Преобразовать аллельные данные, используя референсный геном GRCh38, и определить, какой из аллелей является референсным, а какой альтернативным.

Аргументы командной строки:

--input путь к входному файлу (в формате #CHROM POS ID allele1 allele2)
--output путь к выходному файлу (в формате #CHROM POS ID REF ALT)
--refpath путь к директории с FASTA-файлами хромосом chr[1-22,X,Y,M].fa
--log путь к лог-файлу
--help, -h показать справку

Запуск внутри Docker-контейнера:
```bash
docker run -it --rm `
  -v D:/bioinfo_docker:/code `
  -v D:/bioinfo_docker/GrafPkg:/app `
  -v D:/bioinfo_docker/GrafPkg/sepChrs:/ref/GRCh38.d1.vd1_mainChr/sepChrs/sepChrs `
  bioinfo_tools:latest `
  python3 /code/convert_alleles.py `
    --input /app/FP_SNPs_10k_GB38_twoAllelsFormat.tsv `
    --output /app/FP_SNPs_with_REF_ALT.tsv `
    --refpath /ref/GRCh38.d1.vd1_mainChr/sepChrs/sepChrs `
    --log /app/convert_log.txt
```
### Выходные файлы

FP_SNPs_with_REF_ALT.tsv — файл с результатами в формате:
#CHROM POS ID REF ALT

convert_log.txt — лог-файл работы скрипта: содержит временные метки, сообщения об ошибках и успешных конвертациях

### Что делает скрипт

Скрипт обработал входной файл FP_SNPs_10k_GB38_twoAllelsFormat.tsv, в котором содержались SNP-варианты (по 2 аллеля) с указанием позиции в референсной сборке GRCh38. Для каждой позиции:
- Извлекалась соответствующая буква из FASTA-файла (референсный аллель) с использованием библиотеки pysam.
- Сравнивалась с двумя аллелями (allele1, allele2) в файле.
- Если один из них совпадал с референсом, он записывался как REF, а другой — как ALT.
- Если ни один не совпадал, запись считалась нераспознанной и не включалась в выходной файл.

## Docker и зависимости

Контейнер содержит:
- Python 3
- pysam
- libdeflate
- htslib
- samtools
- bcftools
- vcftools
- скрипт convert_alleles.py

Ожидается, что FASTA-файлы проброшены в папку: /ref/GRCh38.d1.vd1_mainChr/sepChrs/sepChrs/
Файлы вида chr1.fa, chr1.fa.fai,... удалены из папки sepChrs. Также как и файл GRCh38.d1.vd1.fa.

## Результат

Всего SNP во входном файле: 10000

- Успешно обработано: 9991
- Не удалось определить REF: 9

Возможные причины: несовпадение аллелей, нет позиции в FASTA
