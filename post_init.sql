-- post_init.sql
-- ============================================
-- 2. INSERT  DATA
-- ============================================

-- Testnet portfolios
INSERT INTO portfolios (name, description, color) VALUES
    ('Binance Testnet Portfolio', 'Binance Testnet Trading Account', '#0bf031e4'),
    ('Bybit Testnet Portfolio', 'Bybit Testnet Trading Account', '#F7A600'),
    ('OKX Testnet Portfolio', 'OKX Testnet Trading Account', '#d9cfcfff'),
    ('Binance Main Portfolio', 'Binance Main Trading Account', '#ff0000e4');

-- Sample crypto prices (including testnet tokens)
INSERT INTO crypto_prices (symbol, name, current_price,is_stablecoin,atr_30) VALUES
    ('BTC', 'Bitcoin', 93888.00, FALSE, 1938.47),
    ('USDT', 'Tether', 1.00, TRUE, 0.00),
    ('USDC', 'USD Coin', 1.00, TRUE, 0.00),
    ('DASH', 'DASH', 44.93, FALSE, 2.99),
    ('BNB', 'Binance Coin', 908.50, FALSE, 21.88),
    ('XAUT', 'Tether Gold', 4379.20, FALSE, 64.1),
    ('ETH', 'Ethereum', 3275.00, FALSE, 85.35),
    ('CHZ', 'Chiliz', 0.04388, FALSE, 0.00286),
    ('ZEC', 'ZCash', 498.12, FALSE, 41.26);

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
    'USDT',
    1100,
    1.0,
    0,
    'Initial add extra from XAUT deposit from Bybit Testnet'
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
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    105917,
    1.0,
    0,
    'Initial USDT deposit from OKX TestneT'
);2026-01-02 09:10:39
-- Record the DASH/USDT trade
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-02 09:10:39-06'::TIMESTAMPTZ,
    p_crypto_buy := 'XAUT',
    p_amount_buy := 0.253764,
    p_crypto_sell := 'USDT',
    p_amount_sell := 4379.2,
    p_fee := 0.000254018104,
    p_fee_crypto := 'XAUT',
    p_notes := 'Buy XAUT with USDT on Bybit Testnet'
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

INSERT INTO public.transactions(
    portfolio_id, transaction_date, transaction_type, crypto_symbol, 
    amount, price_per_unit, fee, notes
) VALUES (
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Main Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    6743.84692837,
    1.0,
    0,
    'Initial USDT deposit from Binance Testnet'
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

-- Record the DASH/USDT trade
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 14:19:41-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ZEC',
    p_amount_buy := 3.079,
    p_crypto_sell := 'USDT',
    p_amount_sell := 1530.54011,
    p_fee := 0.0030791985,
    p_fee_crypto := 'ZEC',
    p_notes := 'Buy ZEC with USDT on Binance Testnet'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 14:52:07-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ZEC',
    p_amount_buy := 17.0920,
    p_crypto_sell := 'USDT',
    p_amount_sell := 8500.00,
    p_fee := 0.0171092,
    p_fee_crypto := 'ZEC',
    p_notes := 'Buy ZEC with USDT on OKX Testnet'
);

