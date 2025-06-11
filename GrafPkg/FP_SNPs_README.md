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

### Цель преобразования:

Создать файл `FP_SNPs_10k_GB38_twoAllelsFormat.tsv` с колонками:

#CHROM POS ID allele1 allele2

## Шаги предподготовки (bash):

1. Удаление заголовка и фильтрация по хромосомам:
```bash
tail -n +2 FP_SNPs.txt \
| awk -F '\t' '{ if ($2 != "X") print "chr" $2 "\t" $4 "\trs" $1 "\t" $5 "\t" $6 }' \
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
  -v D:/bioinfo_docker/GrafPkg:/app `
  -v D:/bioinfo_docker/convert_alleles.py:/app/convert_alleles.py `
  -v D:/bioinfo_docker/GrafPkg/sepChrs:/ref/GRCh38.d1.vd1_mainChr/sepChrs/sepChrs `
  bioinfo_tools:latest `
  python3 /app/convert_alleles.py --input /app/FP_SNPs_10k_GB38_twoAllelsFormat.tsv --output /app/FP_SNPs_with_REF_ALT.tsv --refpath /ref/GRCh38.d1.vd1_mainChr/sepChrs/sepChrs --log /app/convert_log.txt
```
### Выходные файлы

FP_SNPs_with_REF_ALT.tsv — файл с результатами в формате:
#CHROM POS ID REF ALT

convert_log.txt — лог-файл работы скрипта: содержит временные метки, сообщения об ошибках и успешных конвертациях

### Что делает скрипт

- Читает построчно входной файл
- Для каждой строки извлекает позицию и хромосому
- Получает нуклеотид из соответствующего FASTA-файла
- Сравнивает референсный нуклеотид с allele1 и allele2:
- Если один из них совпадает — он становится REF
- Второй становится ALT
- Если ни один не совпадает — запись логируется как неудачная
- Записывает успешные строки в выходной файл, неудачные — в лог

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

Скрипт позволяет преобразовать данные GRAF в формат, пригодный для популяционного анализа и VCF-инструментов. Он определяет референсный аллель на основании данных GRCh38, и возвращает полноценный файл SNP-вариантов в формате CHROM POS ID REF ALT.
