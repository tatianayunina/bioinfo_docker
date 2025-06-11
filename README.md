# Bioinformatics Tools Docker Image

Этот Docker-образ содержит актуальные версии специализированных биоинформатических программ и библиотек:

- **libdeflate v1.24 (2025-05-11)**
- **htslib 1.22 (2025-05-30)**
- **samtools 1.22 (2025-05-30)**
- **bcftools 1.22 (2025-05-30)**
- **vcftools v0.1.17 (2025-05-15)**

Базовый образ: Ubuntu 22.04.

---

## Сборка Docker-образа

```bash
docker build -t bioinfo_tools:latest .
```

## Запуск Docker-образа в интерактивном режиме
```bash
docker run --rm -it bioinfo_tools:latest bash
```