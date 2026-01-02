-- ============================================
-- MULTI-PORTFOLIO CRYPTO TRACKER - PostgreSQL
-- WITH DOUBLE-ENTRY ACCOUNTING
-- ============================================

-- ============================================
-- 1. CREATE TABLES
-- ============================================

-- Portfolio definitions
CREATE TABLE portfolios (
    portfolio_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(10), -- Hex color code
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Cryptocurrency price tracking
CREATE TABLE crypto_prices (
    crypto_id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    current_price DECIMAL(18, 8),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction log with 4 types: TRANSFER_IN, TRANSFER_OUT, BUY, SELL
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    portfolio_id INT REFERENCES portfolios(portfolio_id),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('TRANSFER_IN', 'TRANSFER_OUT', 'BUY', 'SELL')),
    crypto_symbol VARCHAR(20) NOT NULL,
    amount DECIMAL(18, 8) NOT NULL,
    price_per_unit DECIMAL(18, 8) DEFAULT 0, -- For BUY/SELL, price in base currency
    fee DECIMAL(18, 8) DEFAULT 0,
    notes TEXT,
    -- For double-entry linking (BUY/SELL pairs)
    linked_transaction_id INT REFERENCES transactions(transaction_id),
    trade_pair_id INT, -- Groups related transactions from same trade
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_portfolio ON transactions(portfolio_id);
CREATE INDEX idx_transactions_crypto ON transactions(crypto_symbol);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_trade_pair ON transactions(trade_pair_id);


    

-- ============================================
-- 3. CORE STORED PROCEDURES
-- ============================================

-- Procedure: Execute a TRADE (BUY crypto with another crypto)
-- This creates BOTH transactions automatically (double-entry)
CREATE OR REPLACE FUNCTION execute_trade(
    p_portfolio_id INT,
    p_date TIMESTAMP,
    p_crypto_buy VARCHAR(20),      -- Crypto you're buying
    p_amount_buy DECIMAL(18, 8),   -- Amount you're buying
    p_crypto_sell VARCHAR(20),     -- Crypto you're selling/spending
    p_amount_sell DECIMAL(18, 8),  -- Amount you're selling
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_fee_crypto VARCHAR(20) DEFAULT NULL, -- Which crypto the fee is paid in
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE(
    trade_pair_id INT,
    buy_transaction_id INT,
    sell_transaction_id INT
) AS $$
DECLARE
    v_trade_pair_id INT;
    v_buy_tx_id INT;
    v_sell_tx_id INT;
    v_price_per_unit DECIMAL(18, 8);
BEGIN
    -- Generate unique trade pair ID
    v_trade_pair_id := nextval('transactions_transaction_id_seq');
    
    -- Calculate price per unit (how much of sell crypto per 1 buy crypto)
    v_price_per_unit := p_amount_sell / NULLIF(p_amount_buy, 0);
    
    -- Create BUY transaction (receiving crypto)
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        price_per_unit,
        fee,
        trade_pair_id,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'BUY',
        p_crypto_buy,
        p_amount_buy,
        v_price_per_unit,
        CASE WHEN p_fee_crypto = p_crypto_buy THEN p_fee ELSE 0 END,
        v_trade_pair_id,
        COALESCE(p_notes, '') || ' | Trading ' || p_crypto_sell || ' for ' || p_crypto_buy
    )
    RETURNING transaction_id INTO v_buy_tx_id;
    
    -- Create SELL transaction (spending crypto)
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        price_per_unit,
        fee,
        trade_pair_id,
        linked_transaction_id,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'SELL',
        p_crypto_sell,
        p_amount_sell,
        1 / NULLIF(v_price_per_unit, 0), -- Inverse price
        CASE WHEN p_fee_crypto = p_crypto_sell THEN p_fee ELSE 0 END,
        v_trade_pair_id,
        v_buy_tx_id,
        COALESCE(p_notes, '') || ' | Trading ' || p_crypto_sell || ' for ' || p_crypto_buy
    )
    RETURNING transaction_id INTO v_sell_tx_id;
    
    -- Link the BUY transaction back to SELL
    UPDATE transactions
    SET linked_transaction_id = v_sell_tx_id
    WHERE transaction_id = v_buy_tx_id;
    
    RETURN QUERY
    SELECT v_trade_pair_id, v_buy_tx_id, v_sell_tx_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: TRANSFER IN (deposit from external wallet/exchange)
CREATE OR REPLACE FUNCTION transfer_in(
    p_portfolio_id INT,
    p_date TIMESTAMP,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_cost_basis DECIMAL(18, 8) DEFAULT 0, -- Optional: what you originally paid for it
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
BEGIN
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        price_per_unit,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'TRANSFER_IN',
        p_crypto,
        p_amount,
        p_cost_basis / NULLIF(p_amount, 0),
        COALESCE(p_notes, 'Transfer in from external source')
    )
    RETURNING transaction_id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: TRANSFER OUT (withdrawal to external wallet/exchange)
CREATE OR REPLACE FUNCTION transfer_out(
    p_portfolio_id INT,
    p_date TIMESTAMP,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
    v_current_balance DECIMAL(18, 8);
BEGIN
    -- Check if sufficient balance exists
    SELECT get_crypto_balance(p_portfolio_id, p_crypto) INTO v_current_balance;
    
    IF v_current_balance < (p_amount + p_fee) THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', 
            v_current_balance, (p_amount + p_fee);
    END IF;
    
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        fee,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'TRANSFER_OUT',
        p_crypto,
        p_amount,
        p_fee,
        COALESCE(p_notes, 'Transfer out to external destination')
    )
    RETURNING transaction_id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Simple BUY with fiat/stablecoin (no double entry, just acquisition)
CREATE OR REPLACE FUNCTION buy_with_fiat(
    p_portfolio_id INT,
    p_date TIMESTAMP,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_price_per_unit DECIMAL(18, 8),
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
BEGIN
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        price_per_unit,
        fee,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'BUY',
        p_crypto,
        p_amount,
        p_price_per_unit,
        p_fee,
        COALESCE(p_notes, 'Buy with fiat/stablecoin')
    )
    RETURNING transaction_id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Simple SELL to fiat/stablecoin (no double entry, just disposal)
CREATE OR REPLACE FUNCTION sell_to_fiat(
    p_portfolio_id INT,
    p_date TIMESTAMP,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_price_per_unit DECIMAL(18, 8),
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
    v_current_balance DECIMAL(18, 8);
BEGIN
    -- Check if sufficient balance exists
    SELECT get_crypto_balance(p_portfolio_id, p_crypto) INTO v_current_balance;
    
    IF v_current_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', 
            v_current_balance, p_amount;
    END IF;
    
    INSERT INTO transactions (
        portfolio_id,
        transaction_date,
        transaction_type,
        crypto_symbol,
        amount,
        price_per_unit,
        fee,
        notes
    ) VALUES (
        p_portfolio_id,
        p_date,
        'SELL',
        p_crypto,
        p_amount,
        p_price_per_unit,
        p_fee,
        COALESCE(p_notes, 'Sell to fiat/stablecoin')
    )
    RETURNING transaction_id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- Function: Get current balance of a crypto in a portfolio
CREATE OR REPLACE FUNCTION get_crypto_balance(
    p_portfolio_id INT,
    p_crypto VARCHAR(20)
)
RETURNS DECIMAL(18, 8) AS $$
DECLARE
    v_balance DECIMAL(18, 8);
BEGIN
    SELECT COALESCE(
        SUM(CASE 
            WHEN transaction_type IN ('BUY', 'TRANSFER_IN') THEN amount
            WHEN transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(amount + fee)
            ELSE 0
        END),
        0
    )
    INTO v_balance
    FROM transactions
    WHERE portfolio_id = p_portfolio_id
    AND crypto_symbol = p_crypto;
    
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;

-- Function: Get all balances for a portfolio
CREATE OR REPLACE FUNCTION get_portfolio_balances(p_portfolio_id INT)
RETURNS TABLE(
    crypto_symbol VARCHAR(20),
    balance DECIMAL(18, 8)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.crypto_symbol,
        SUM(CASE 
            WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
            WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
            ELSE 0
        END) AS balance
    FROM transactions t
    WHERE t.portfolio_id = p_portfolio_id
    GROUP BY t.crypto_symbol
    HAVING SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END) > 0.00000001
    ORDER BY balance DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get trade details (both sides of a trade)
CREATE OR REPLACE FUNCTION get_trade_details(p_trade_pair_id INT)
RETURNS TABLE(
    transaction_id INT,
    transaction_type VARCHAR(20),
    crypto_symbol VARCHAR(20),
    amount DECIMAL(18, 8),
    price_per_unit DECIMAL(18, 8),
    fee DECIMAL(18, 8),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.transaction_id,
        t.transaction_type,
        t.crypto_symbol,
        t.amount,
        t.price_per_unit,
        t.fee,
        t.notes
    FROM transactions t
    WHERE t.trade_pair_id = p_trade_pair_id
    ORDER BY t.transaction_type DESC; -- BUY first, then SELL
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. VIEWS FOR HOLDINGS & REPORTING
-- ============================================

-- View: Current Holdings with proper balance calculation
CREATE OR REPLACE VIEW v_holdings AS
SELECT 
    p.portfolio_id,
    p.name AS portfolio_name,
    t.crypto_symbol,
    -- Calculate net balance
    SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END) AS total_amount,
    -- Calculate total cost (what you paid for current holdings)
    SUM(CASE 
        WHEN t.transaction_type = 'BUY' THEN t.amount * t.price_per_unit + t.fee
        WHEN t.transaction_type = 'TRANSFER_IN' THEN t.amount * t.price_per_unit
        WHEN t.transaction_type = 'SELL' THEN -(t.amount * t.price_per_unit - t.fee)
        WHEN t.transaction_type = 'TRANSFER_OUT' THEN 0
        ELSE 0
    END) AS total_cost,
    -- Average cost per unit
    SUM(CASE 
        WHEN t.transaction_type = 'BUY' THEN t.amount * t.price_per_unit + t.fee
        WHEN t.transaction_type = 'TRANSFER_IN' THEN t.amount * t.price_per_unit
        WHEN t.transaction_type = 'SELL' THEN -(t.amount * t.price_per_unit - t.fee)
        ELSE 0
    END) / NULLIF(SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END), 0) AS avg_cost_per_unit,
    -- Current price
    cp.current_price,
    -- Current value
    SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END) * cp.current_price AS current_value,
    -- Profit/Loss
    (SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END) * cp.current_price) - 
    SUM(CASE 
        WHEN t.transaction_type = 'BUY' THEN t.amount * t.price_per_unit + t.fee
        WHEN t.transaction_type = 'TRANSFER_IN' THEN t.amount * t.price_per_unit
        WHEN t.transaction_type = 'SELL' THEN -(t.amount * t.price_per_unit - t.fee)
        ELSE 0
    END) AS profit_loss,
    -- P/L Percentage
    ((SUM(CASE 
        WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
        WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
        ELSE 0
    END) * cp.current_price) - 
    SUM(CASE 
        WHEN t.transaction_type = 'BUY' THEN t.amount * t.price_per_unit + t.fee
        WHEN t.transaction_type = 'TRANSFER_IN' THEN t.amount * t.price_per_unit
        WHEN t.transaction_type = 'SELL' THEN -(t.amount * t.price_per_unit - t.fee)
        ELSE 0
    END)) / NULLIF(SUM(CASE 
        WHEN t.transaction_type = 'BUY' THEN t.amount * t.price_per_unit + t.fee
        WHEN t.transaction_type = 'TRANSFER_IN' THEN t.amount * t.price_per_unit
        WHEN t.transaction_type = 'SELL' THEN -(t.amount * t.price_per_unit - t.fee)
        ELSE 0
    END), 0) * 100 AS profit_loss_percent,
    -- Number of transactions
    COUNT(*) AS transaction_count
FROM transactions t
JOIN portfolios p ON t.portfolio_id = p.portfolio_id
LEFT JOIN crypto_prices cp ON t.crypto_symbol = cp.symbol
WHERE p.is_active = TRUE
GROUP BY p.portfolio_id, p.name, t.crypto_symbol, cp.current_price
HAVING SUM(CASE 
    WHEN t.transaction_type IN ('BUY', 'TRANSFER_IN') THEN t.amount
    WHEN t.transaction_type IN ('SELL', 'TRANSFER_OUT') THEN -(t.amount + t.fee)
    ELSE 0
END) > 0.00000001;

-- View: Portfolio Summary
CREATE OR REPLACE VIEW v_portfolio_summary AS
SELECT 
    portfolio_id,
    portfolio_name,
    SUM(total_cost) AS total_invested,
    SUM(current_value) AS current_value,
    SUM(profit_loss) AS total_profit_loss,
    (SUM(profit_loss) / NULLIF(SUM(total_cost), 0)) * 100 AS total_profit_loss_percent,
    COUNT(DISTINCT crypto_symbol) AS unique_cryptos,
    SUM(transaction_count) AS total_transactions
FROM v_holdings
GROUP BY portfolio_id, portfolio_name;

-- View: Transaction History with Trade Pairing
CREATE OR REPLACE VIEW v_transaction_history AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    p.name AS portfolio_name,
    t.transaction_type,
    t.crypto_symbol,
    t.amount,
    t.price_per_unit,
    t.fee,
    t.trade_pair_id,
    t.linked_transaction_id,
    -- If part of a trade, show the other side
    CASE 
        WHEN t.linked_transaction_id IS NOT NULL THEN
            (SELECT t2.crypto_symbol || ' (' || t2.amount || ')'
             FROM transactions t2 
             WHERE t2.transaction_id = t.linked_transaction_id)
        ELSE NULL
    END AS trade_counterpart,
    t.notes,
    t.created_at
FROM transactions t
JOIN portfolios p ON t.portfolio_id = p.portfolio_id
ORDER BY t.transaction_date DESC, t.transaction_id DESC;

-- ============================================
-- 6. USAGE EXAMPLES
-- ============================================

-- ===========================================
-- QUICK VIEW: Check Testnet Portfolio Balances
-- ===========================================

-- View Binance Testnet balances
/*
SELECT * FROM get_portfolio_balances(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio')
);
*/

-- View Bybit Testnet balances
/*
SELECT * FROM get_portfolio_balances(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio')
);
*/

-- View OKX Testnet balances
/*
SELECT * FROM get_portfolio_balances(
    (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio')
);
*/

-- View ALL testnet portfolios summary
/*
SELECT 
    p.name AS portfolio_name,
    ps.*
FROM v_portfolio_summary ps
JOIN portfolios p ON ps.portfolio_id = p.portfolio_id
WHERE p.name LIKE '%Testnet%'
ORDER BY ps.current_value DESC;
*/

-- View detailed holdings for all testnet portfolios
/*
SELECT 
    portfolio_name,
    crypto_symbol,
    total_amount,
    ROUND(avg_cost_per_unit::NUMERIC, 2) AS avg_cost,
    ROUND(current_value::NUMERIC, 2) AS current_value,
    ROUND(profit_loss::NUMERIC, 2) AS profit_loss,
    ROUND(profit_loss_percent::NUMERIC, 2) AS profit_loss_pct
FROM v_holdings
WHERE portfolio_name LIKE '%Testnet%'
ORDER BY portfolio_name, current_value DESC;
*/

-- ===========================================
-- TRADING EXAMPLES FOR TESTNET PORTFOLIOS
-- ===========================================

-- Example 1: Transfer IN (deposit BTC from external wallet)
/*
SELECT transfer_in(
    p_portfolio_id := 1,
    p_date := CURRENT_TIMESTAMP,
    p_crypto := 'BTC',
    p_amount := 0.5,
    p_cost_basis := 20000,  -- What you originally paid
    p_notes := 'Transfer from Coinbase'
);
*/

-- Example 2: Buy crypto with fiat/USDT
/*
SELECT buy_with_fiat(
    p_portfolio_id := 1,
    p_date := CURRENT_TIMESTAMP,
    p_crypto := 'ETH',
    p_amount := 10,
    p_price_per_unit := 2900,
    p_fee := 5,
    p_notes := 'DCA purchase'
);
*/

-- Example 3: TRADE on Binance Testnet - Exchange USDT for BTC
/*
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := CURRENT_TIMESTAMP,
    p_crypto_buy := 'BTC',      -- Receiving 0.01 BTC
    p_amount_buy := 0.01,
    p_crypto_sell := 'USDT',    -- Spending 430 USDT
    p_amount_sell := 430,
    p_fee := 0.43,
    p_fee_crypto := 'USDT',
    p_notes := 'Buy BTC with USDT'
);
*/

-- Example 4: TRADE on Bybit Testnet - Exchange BTC for ETH
/*
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    p_date := CURRENT_TIMESTAMP,
    p_crypto_buy := 'ETH',      -- Receiving 10 ETH
    p_amount_buy := 10,
    p_crypto_sell := 'BTC',     -- Spending ~0.067 BTC
    p_amount_sell := 0.067,
    p_fee := 0.00001,
    p_fee_crypto := 'BTC',
    p_notes := 'Swap BTC to ETH'
);
*/

-- Example 5: TRADE on OKX Testnet - Exchange ETH for BCH
/*
SELECT * FROM execute_trade(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'OKX Testnet Portfolio'),
    p_date := CURRENT_TIMESTAMP,
    p_crypto_buy := 'BCH',
    p_amount_buy := 5,
    p_crypto_sell := 'ETH',
    p_amount_sell := 0.655,
    p_fee := 0.001,
    p_fee_crypto := 'ETH',
    p_notes := 'Trading ETH for BCH'
);
*/

-- Example 6: Sell crypto to fiat/USDT on Binance
/*
SELECT sell_to_fiat(
    p_portfolio_id := (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio'),
    p_date := CURRENT_TIMESTAMP,
    p_crypto := 'BNB',
    p_amount := 1,
    p_price_per_unit := 310,
    p_fee := 0.31,
    p_notes := 'Sell BNB for USDT'
);
*/

-- Example 7: Transfer OUT (withdraw to external wallet)
/*
SELECT transfer_out(
    p_portfolio_id := 1,
    p_date := CURRENT_TIMESTAMP,
    p_crypto := 'BTC',
    p_amount := 0.2,
    p_fee := 0.0001,
    p_notes := 'Transfer to cold wallet'
);
*/

-- Example 8: Check balance of BTC in Bybit portfolio
/*
SELECT get_crypto_balance(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Bybit Testnet Portfolio'),
    'BTC'
);
*/

-- Example 9: Get all balances for Binance testnet
/*
SELECT * FROM get_portfolio_balances(
    (SELECT portfolio_id FROM portfolios WHERE name = 'Binance Testnet Portfolio')
);
*/

-- Example 10: View trade details
/*
SELECT * FROM get_trade_details(1);  -- Replace 1 with actual trade_pair_id
*/

-- Example 11: View all holdings
/*
SELECT * FROM v_holdings
ORDER BY portfolio_name, current_value DESC;
*/

-- Example 12: View transaction history with trade pairs
/*
SELECT * FROM v_transaction_history
WHERE portfolio_name = 'Binance Testnet Portfolio'
LIMIT 20;
*/

-- Example 13: View portfolio summary
/*
SELECT * FROM v_portfolio_summary;
*/

-- Example 14: Update crypto price
/*
UPDATE crypto_prices SET current_price = 44000 WHERE symbol = 'BTC';
UPDATE crypto_prices SET current_price = 3000 WHERE symbol = 'ETH';
*/

-- ===========================================
-- USEFUL QUERIES FOR TESTNET PORTFOLIOS
-- ===========================================

-- Compare all 3 testnet portfolios side by side
/*
SELECT 
    p.name,
    ROUND(ps.total_invested::NUMERIC, 2) AS invested,
    ROUND(ps.current_value::NUMERIC, 2) AS value,
    ROUND(ps.total_profit_loss::NUMERIC, 2) AS pnl,
    ROUND(ps.total_profit_loss_percent::NUMERIC, 2) AS pnl_pct,
    ps.unique_cryptos
FROM v_portfolio_summary ps
JOIN portfolios p ON ps.portfolio_id = p.portfolio_id
WHERE p.name LIKE '%Testnet%'
ORDER BY ps.current_value DESC;
*/

-- Total value across all testnet portfolios
/*
SELECT 
    SUM(current_value) AS total_testnet_value,
    SUM(total_invested) AS total_testnet_invested,
    SUM(total_profit_loss) AS total_testnet_pnl
FROM v_portfolio_summary ps
JOIN portfolios p ON ps.portfolio_id = p.portfolio_id
WHERE p.name LIKE '%Testnet%';
*/

-- Asset distribution across testnet portfolios
/*
SELECT 
    crypto_symbol,
    COUNT(DISTINCT portfolio_name) AS portfolios_holding,
    SUM(total_amount) AS total_amount,
    ROUND(SUM(current_value)::NUMERIC, 2) AS total_value
FROM v_holdings
WHERE portfolio_name LIKE '%Testnet%'
GROUP BY crypto_symbol
ORDER BY total_value DESC;
*/