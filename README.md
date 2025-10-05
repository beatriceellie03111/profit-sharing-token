# Profit Sharing Token

A Stacks smart contract implementation for tokens with built-in profit sharing on resale with automated revenue distribution to token holders.

## Overview

This project implements a novel token system where holders automatically receive a share of profits from secondary market sales and resale activities. The system consists of two core contracts that work together to calculate and distribute profits transparently.

## Architecture

### Core Contracts

1. **profit-calculator**: Calculates profit percentages on token resales and secondary market activity
2. **revenue-distributor**: Automated distribution system for sharing profits among token holders

## Features

- **Automated Profit Sharing**: Token holders receive proportional shares of resale profits
- **Transparent Calculations**: All profit calculations are performed on-chain
- **Fair Distribution**: Revenue is distributed based on token holdings and participation
- **Secondary Market Integration**: Captures profits from various trading activities

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks smart contract development toolkit
- [Node.js](https://nodejs.org/) - JavaScript runtime for testing
- [Git](https://git-scm.com/) - Version control

### Installation

1. Clone the repository:
```bash
git clone https://github.com/zaraflorence7218/profit-sharing-token.git
cd profit-sharing-token
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

### Running Tests

Execute the test suite to verify contract functionality:

```bash
clarinet test
```

For detailed test output:
```bash
npm test
```

## Contract Details

### Profit Calculator Contract

The `profit-calculator` contract handles:
- Calculation of profit percentages on token resales
- Tracking of secondary market activity
- Determination of distributable profits
- Integration with trading platforms

Key functions:
- `calculate-profit-percentage`: Computes the profit margin on resales
- `track-secondary-sale`: Records secondary market transactions
- `get-distributable-amount`: Returns the amount available for distribution

### Revenue Distributor Contract

The `revenue-distributor` contract manages:
- Automated distribution of profits to token holders
- Proportional allocation based on holdings
- Distribution scheduling and execution
- Holder registration and management

Key functions:
- `distribute-profits`: Executes profit distribution to all eligible holders
- `register-holder`: Adds new token holders to distribution system
- `calculate-share`: Determines individual holder's share percentage
- `claim-profits`: Allows holders to claim their distributed profits

## Usage

### For Token Holders

1. **Automatic Registration**: Token holders are automatically registered upon first token acquisition
2. **Profit Distribution**: Profits are distributed automatically based on holding percentage
3. **Claiming Rewards**: Use the `claim-profits` function to withdraw your share

### For Developers

1. **Integration**: Import contracts into your Stacks application
2. **Customization**: Modify profit percentage calculations as needed
3. **Extension**: Add additional profit sources or distribution mechanisms

## Testing

The project includes comprehensive tests covering:
- Basic contract functionality
- Profit calculation accuracy
- Distribution fairness
- Edge cases and error handling

Run specific test suites:
```bash
# Test profit calculations
clarinet test tests/profit-calculator_test.ts

# Test revenue distribution
clarinet test tests/revenue-distributor_test.ts
```

## Deployment

### Testnet Deployment

1. Configure network settings in `settings/Testnet.toml`
2. Deploy contracts:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure network settings in `settings/Mainnet.toml`
2. Deploy contracts:
```bash
clarinet deploy --mainnet
```

## Security Considerations

- All profit calculations are performed on-chain for transparency
- Distribution mechanisms include safeguards against manipulation
- Contract upgrades follow established governance procedures
- Regular security audits are recommended before mainnet deployment

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Open an issue on GitHub
- Join our community discussions
- Review the documentation at [docs.hiro.so](https://docs.hiro.so)

## Roadmap

- [ ] Enhanced profit calculation algorithms
- [ ] Multi-token support
- [ ] Advanced distribution scheduling
- [ ] Integration with major DEX platforms
- [ ] Mobile wallet compatibility
- [ ] Governance token implementation

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Hiro Systems for development tools
- Community contributors and testers