-- ============================================
-- 2. INSERT  DATA
-- ============================================

-- Testnet portfolios
INSERT INTO portfolios (name, description, color) VALUES
    ('Binance Testnet Portfolio', 'Binance Testnet Trading Account', '#0bf031e4'),
    ('Bybit Testnet Portfolio', 'Bybit Testnet Trading Account', '#F7A600'),
    ('OKX Testnet Portfolio', 'OKX Testnet Trading Account', '#d9cfcfff');

-- Sample crypto prices (including testnet tokens)
INSERT INTO crypto_prices (symbol, name, current_price) VALUES
    ('BTC', 'Bitcoin', 43000.00),
    ('USDT', 'Tether', 1.00),
    ('USDC', 'USD Coin', 1.00);

-- ============================================
-- BINANCE TESTNET PORTFOLIO - Initial Deposits
-- ============================================

-- Add 0.05 BTC
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BTC',
    0.05,
    0,
    'Initial testnet deposit'
);

-- Add 5000 USDC
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'USDC',
    5000,
    0,
    'Initial testnet deposit'
);

-- Add 5000 USDT
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'USDT',
    5000,
    0,
    'Initial testnet deposit'
);

-- Add 1 ETH
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'ETH',
    1,
    0,
    'Initial testnet deposit'
);

-- Add 2 BNB
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BNB',
    2,
    0,
    'Initial testnet deposit'
);

-- ============================================
-- BYBIT TESTNET PORTFOLIO - Initial Deposits
-- ============================================

-- Add 1 BTC
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BTC',
    1,
    0,
    'Initial testnet deposit'
);

-- Add 50000 USDC
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'USDC',
    50000,
    0,
    'Initial testnet deposit'
);

-- Add 48307 USDT
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'USDT',
    48307,
    0,
    'Initial testnet deposit'
);

-- Add 1 ETH
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'ETH',
    1,
    0,
    'Initial testnet deposit'
);

-- Add 0.253764 XAUT
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'XAUT',
    0.253764,
    0,
    'Initial testnet deposit'
);

-- Add 1.02277620 BCH
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BCH',
    1.02277620,
    0,
    'Initial testnet deposit'
);

-- ============================================
-- OKX TESTNET PORTFOLIO - Initial Deposits
-- ============================================

-- Add 1 BTC
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BTC',
    1,
    0,
    'Initial testnet deposit'
);

-- Add 1 ETH
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'ETH',
    1,
    0,
    'Initial testnet deposit'
);

-- Add 1.0221 BCH
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'BCH',
    1.0221,
    0,
    'Initial testnet deposit'
);

-- Add 15215 USDT
SELECT transfer_in(
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    CURRENT_TIMESTAMP,
    'USDT',
    15215,
    0,
    'Initial testnet deposit'
);

