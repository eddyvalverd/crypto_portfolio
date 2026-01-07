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
INSERT INTO crypto_prices (symbol, name, current_price,is_stablecoin,atr_30,rank) VALUES
    ('BTC', 'Bitcoin', 91938.00, FALSE, 1938.47,1),
    ('ETH', 'Ethereum', 3211, FALSE, 123.37,2),
    ('XRP', 'XRP', 2.24, FALSE, 0.0896,4),
    ('SOL', 'Solana', 137.82, FALSE, 6.58,6),
    ('DOGE', 'Dogecoin', 0.1480, FALSE, 0.00768,9),
    ('ADA', 'Cardano', 0.4115, FALSE, 0.0251,10),
    ('BCH', 'Bitcoin Cash', 629.44, FALSE, 31.4,11),
    ('LINK', 'Chainlink', 13.64, FALSE, 0.67,12),
    ('USDT', 'Tether', 1.00, TRUE, 0.00,3),
    ('USDC', 'USD Coin', 1.00, TRUE, 0.00,7),
    ('DASH', 'DASH', 41.93, FALSE, 3.55,91),
    ('BNB', 'Binance Coin', 904.79, FALSE, 26.58,5),
    ('XAUT', 'Tether Gold', 4442.74, FALSE, 57.4,4),
    ('CHZ', 'Chiliz', 0.04318, FALSE, 0.00266,100),
    ('ZEC', 'ZCash', 486.15, FALSE, 41.26,14),
    ('TRX', 'TRON', 0.2958, FALSE, 0.0045,8),
    ('MYX', 'MYX Finance', 4.93, FALSE, 0.5963,60);

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
    140079.4364,
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
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),  -- extra parentheses
    '2026-01-02 06:53:38'::timestamp,
    'TRANSFER_IN',
    'USDT',
    105917,
    1.0,
    0,
    'Initial USDT deposit from OKX TestneT'
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

-- Record the XAUT/USDT trade
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-02 09:10:39-06'::TIMESTAMPTZ,
    p_crypto_buy := 'XAUT',
    p_amount_buy := 0.253764,
    p_crypto_sell := 'USDT',
    p_amount_sell := 1100,
    p_fee := 0.000254018104,
    p_fee_crypto := 'XAUT',
    p_notes := 'Buy XAUT with USDT on Bybit'
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
    p_notes := 'Buy DASH with USDT on Binance, , order No. 152631877'
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
    p_notes := 'Buy ZEC with USDT on Binance Testnet, order no 585023209'
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
    p_notes := 'Buy ZEC with USDT on OKX Testnet, order no 3195399537557331968'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 09:10:39-06'::TIMESTAMPTZ,
    p_crypto_buy := 'BTC',
    p_amount_buy := 92969.49,
    p_crypto_sell := 'USDC',
    p_amount_sell := 6079.2749511,
    p_fee := 0.00006212,
    p_fee_crypto := 'BTC',
    p_notes := 'Buy BTC with USDC on Binance Testnet, order no 444647893'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:02:04-06'::TIMESTAMPTZ,
    p_crypto_buy := 'SOL',
    p_amount_buy := 19.264,
    p_crypto_sell := 'USDT',
    p_amount_sell := 2686.17216,
    p_fee := 0.019264,
    p_fee_crypto := 'SOL',
    p_notes := 'Buy SOL with USDT on Binance Testnet, order no 587133075'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:13:02-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ADA',
    p_amount_buy := 4877.1,
    p_crypto_sell := 'USDT',
    p_amount_sell := 2010.34062 ,
    p_fee := 4.8771,
    p_fee_crypto := 'ADA',
    p_notes := 'Buy ADA with USDT on Binance Testnet, order no 201877196'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:13:02-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ADA',
    p_amount_buy := 173.2,
    p_crypto_sell := 'USDT',
    p_amount_sell := 71.41036 ,
    p_fee := 0.00005883,
    p_fee_crypto := 'BNB',
    p_notes := 'Buy ADA with USDT on Binance Testnet, , order no 201877196'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:13:02-06'::TIMESTAMPTZ,
    p_crypto_buy := 'LINK',
    p_amount_buy := 131.75
    p_crypto_sell := 'USDC',
    p_amount_sell := 1819.4675 ,
    p_fee := 0.1251625 ,
    p_fee_crypto := 'LINK',
    p_notes := 'Buy ADA with USDT on Binance Testnet, order no 37869347'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:13:02-06'::TIMESTAMPTZ,
    p_crypto_buy := 'LINK',
    p_amount_buy := 58
    p_crypto_sell := 'USDT',
    p_amount_sell := 800.98,
    p_fee := 0.058 ,
    p_fee_crypto := 'LINK',
    p_notes := 'Buy ADA with USDT on Binance Testnet, order no104044101'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:32:49-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 5416
    p_crypto_sell := 'USDT',
    p_amount_sell := 234.02536,
    p_fee := 5.416 ,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDT on Binance Testnet, Order No 49853456'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:32:49-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 5817
    p_crypto_sell := 'USDT',
    p_amount_sell := 251.41074,
    p_fee := 5.817  ,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDT on Binance Testnet, Order No 49853456'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:32:49-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 19997
    p_crypto_sell := 'USDT',
    p_amount_sell := 864.47031,
    p_fee := 19.997 ,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDT on Binance Testnet, Order No 49853456'
);
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := '2026-01-06 22:32:49-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 16425
    p_crypto_sell := 'USDT',
    p_amount_sell := 710.217,
    p_fee := 16.425 ,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDT on Binance Testnet, Order No 49853456'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-06 21:53:37-06'::TIMESTAMPTZ,
    p_crypto_buy := 'BTC',
    p_amount_buy := 0.654303
    p_crypto_sell := 'USDT',
    p_amount_sell := 60,725.8159245,
    p_fee := 0.000654303919 ,
    p_fee_crypto := 'BTC',
    p_notes := 'Buy BTC with USDT on Bybit Testnet, Order ID 49554944'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-06 22:16:22-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ADA',
    p_amount_buy := 50781.99,
    p_crypto_sell := 'USDC',
    p_amount_sell := 20927.260265,
    p_fee := 50.781995306964 ,
    p_fee_crypto := 'ADA',
    p_notes := 'Buy ADA with USDC on Bybit Testnet, Order ID 71421696'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-06 22:26:09-06'::TIMESTAMPTZ,
    p_crypto_buy := 'LINK',
    p_amount_buy := 51905.590,
    p_crypto_sell := 'USDT',
    p_amount_sell := 26278.08984,
    p_fee := 1.905590271936 ,
    p_fee_crypto := 'LINK',
    p_notes := 'Buy LINK with USDT on Bybit Testnet, Order ID 37497344'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := '2026-01-06 22:26:09-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 167934.03,
    p_crypto_sell := 'USDC',
    p_amount_sell := 7268.1849334,
    p_fee := 167.934032659426 ,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDC on Bybit Testnet, Order ID 88075008'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 21:57:25-06'::TIMESTAMPTZ,
    p_crypto_buy := 'BTC',
    p_amount_buy := 0.36365619,
    p_crypto_sell := 'USDT',
    p_amount_sell := 33695.12,
    p_fee := 0.00036402,
    p_fee_crypto := 'BTC',
    p_notes := 'Buy BTC with USDT on OKX Testnet, order no 3196255797739610112'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 22:05:28-06'::TIMESTAMPTZ,
    p_crypto_buy := 'SOL',
    p_amount_buy := 107.302035,
    p_crypto_sell := 'USDT',
    p_amount_sell := 33695.12,
    p_fee := 0.10730203,
    p_fee_crypto := 'SOL',
    p_notes := 'Buy SOL with USDT on OKX Testnet, order no 3196271990135414784'
);
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 22:19:08-06'::TIMESTAMPTZ,
    p_crypto_buy := 'ADA',
    p_amount_buy := 28129.3782,
    p_crypto_sell := 'USDT',
    p_amount_sell := 33695.12,
    p_fee := 28.1241757,
    p_fee_crypto := 'ADA',
    p_notes := 'Buy ADA with USDT on OKX Testnet, order no 3196271990135414784'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 22:27:59-06'::TIMESTAMPTZ,
    p_crypto_buy := 'LINK',
    p_amount_buy := 1053.8021,
    p_crypto_sell := 'USDT',
    p_amount_sell := 14517.29,
    p_fee := 1.05375865,
    p_fee_crypto := 'LINK',
    p_notes := 'Buy LINK with USDT on OKX Testnet, order no 3196317317508980736'
);

SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := '2026-01-06 22:40:36-06'::TIMESTAMPTZ,
    p_crypto_buy := 'CHZ',
    p_amount_buy := 1053.8021,
    p_crypto_sell := 'USDT',
    p_amount_sell := 14517.29,
    p_fee := 1.05375865,
    p_fee_crypto := 'CHZ',
    p_notes := 'Buy CHZ with USDT on OKX Testnet, order no 3196317317508980736'
);