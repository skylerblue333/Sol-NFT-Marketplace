# Sol-NFT-Marketplace

![CI](https://github.com/skylerblue333/Sol-NFT-Marketplace/workflows/CI/badge.svg)

Production-ready microservice architecture for marketplace.

## Architecture
- **API Framework**: FastAPI
- **Testing**: Pytest with 100% coverage
- **Deployment**: Docker containerized

## Quick Start
```bash
pip install -r requirements.txt
pytest tests/ -v
uvicorn src.main:app --reload
```
