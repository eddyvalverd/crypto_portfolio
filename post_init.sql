-- post_init.sql
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
    ('BTC', 'Bitcoin', 93888.00),
    ('USDT', 'Tether', 1.00),
    ('USDC', 'USD Coin', 1.00),
    ('DASH', 'DASH', 44.93) ,
    ('BNB', 'Binance Coin', 908.50),
    ('XAUT', 'Tether Gold', 4379.20);

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

-- Record the DASH/USDT trade
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-02 09:10:39-06'::TIMESTAMPTZ,
    p_crypto_buy := 'DASH',
    p_amount_buy := 33.6,
    p_crypto_sell := 'USDT',
    p_amount_sell := 1396.6145,
    p_fee := 0.01985,
    p_fee_crypto := 'DASH',
    p_notes := 'Buy DASH with USDT on Binance'
);

-- Record the BNB fee as a separate transaction (since it's paid in a different crypto)
INSERT INTO transactions (
    portfolio_id,
    transaction_date,
    transaction_type,
    crypto_symbol,
    amount,
    fee,
    notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    '2026-01-02 09:10:39-06'::TIMESTAMPTZ,
    'TRANSFER_OUT',
    'BNB',
    0,
    0.00048917,
    'BNB fee for DASH/USDT trade'
);

-- Verify your balances after the trade
SELECT * FROM get_portfolio_balances(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio')
);