# DeepFinance

**DeepFinance** is a powerful AI-driven financial analysis and trading platform inspired by the strategic wisdom of Zeus. This tool leverages cutting-edge LLM models to provide accurate forecasts: DeepSeek R1 8B for reasoning and Mistral 7B for summarization, and algorithmic insights for financial markets live.

![DeepFinance Logo](DeepFinanceLogo.png)

## Features
- Advanced machine learning models for financial forecasting.
- Real-time data analysis with adaptive trading strategies.
- Modular architecture for easy customization and expansion.

## Requirements
To run **DeepFinance**, you'll need the following dependencies:

```
numpy
pandas
scikit-learn
tensorflow
pytorch
ccxt
matplotlib
zeromq
langchain
```

Install dependencies with:
```bash
pip install -r requirements.txt
```

## Installation
1. Clone this repository:
```bash
git clone https://github.com/javierchacon262/DeepFinance.git
```
2. Navigate to the project directory:
```bash
cd DeepFinance
```
3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage
To launch DeepFinance, run:
```bash
python run.py
```

### Configuration
- Update the EA inputs when loading it in the chart, default config should work just fine, specially if you recide to use the standard chart template in your MT4 chart.
- After succesfully loading the EA you need to execute the run.py file

## Roadmap
- [ ] Implement reinforcement learning for trading strategies.
- [ ] Add support for additional financial markets.
- [ ] Develop a user-friendly web interface for enhanced usability.

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature-name`).
3. Commit your changes (`git commit -m "Add new feature"`).
4. Push the branch (`git push origin feature-name`).
5. Open a pull request.

## License
This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.

## Contact
For inquiries or support, please contact **[Your Email or Contact Info]**.

