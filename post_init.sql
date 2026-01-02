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
    ('BTC', 'Bitcoin', 89312.00),
    ('USDT', 'Tether', 1.00),
    ('USDC', 'USD Coin', 1.00);

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    11031.71899874,
    1.0,
    0,
    'Initial USDT deposit from Binance Testnet'
);

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDC',
    7917.19,
    1.0,
    0,
    'Initial USDC deposit from Binance Testnet'
);


INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    138979.4364,
    1.0,
    0,
    'Initial USDT deposit from Bybit Testnet'
);

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDC',
    50000.00,
    1.0,
    0,
    'Initial USDC deposit from Bybit Testnet'
);

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'XAUT',
    0.253764,
    4379.2,
    0,
    'Initial XAUT deposit from Bybit Testnet'
);

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    105917,
    1.0,
    0,
    'Initial USDT deposit from OKX TestneT'
);