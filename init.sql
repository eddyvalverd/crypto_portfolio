--init.sql
-- ============================================
-- MULTI-PORTFOLIO CRYPTO TRACKER - PostgreSQL
-- WITH DOUBLE-ENTRY ACCOUNTING
-- COSTA RICAN TIME ZONE (America/Costa_Rica)
-- ============================================

-- Set default timezone for this session
SET timezone = 'America/Costa_Rica';

-- ============================================
-- 1. CREATE TABLES
-- ============================================

-- Portfolio definitions
CREATE TABLE portfolios (
    portfolio_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(10), -- Hex color code
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica'),
    is_active BOOLEAN DEFAULT TRUE
);

-- Cryptocurrency price tracking
CREATE TABLE crypto_prices (
    crypto_id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    current_price DECIMAL(18, 8),
    last_updated TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica'),
    is_stablecoin BOOLEAN DEFAULT FALSE,
    atr_30 DECIMAL(18, 8)
);

-- Transaction log with 4 types: TRANSFER_IN, TRANSFER_OUT, BUY, SELL
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    portfolio_id INT REFERENCES portfolios(portfolio_id),
    transaction_date TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica'),
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('TRANSFER_IN', 'TRANSFER_OUT', 'BUY', 'SELL')),
    crypto_symbol VARCHAR(20) NOT NULL,
    amount DECIMAL(18, 8) NOT NULL,
    price_per_unit DECIMAL(18, 8) DEFAULT 0, -- For BUY/SELL, price in base currency
    fee DECIMAL(18, 8) DEFAULT 0,
    notes TEXT,
    -- For double-entry linking (BUY/SELL pairs)
    linked_transaction_id INT REFERENCES transactions(transaction_id),
    trade_pair_id INT, -- Groups related transactions from same trade
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica')
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
-- Step 3: Create improved execute_trade function
CREATE OR REPLACE FUNCTION execute_trade(
    p_portfolio_id INT,
    p_date TIMESTAMPTZ,
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
    v_buy_price_per_unit DECIMAL(18, 8);
    v_sell_price_per_unit DECIMAL(18, 8);
    v_date_cr TIMESTAMPTZ;
    v_is_sell_stablecoin BOOLEAN;
    v_is_buy_stablecoin BOOLEAN;
BEGIN
    -- Ensure date is in Costa Rica timezone
    v_date_cr := p_date AT TIME ZONE 'America/Costa_Rica';
    
    -- Generate unique trade pair ID
    v_trade_pair_id := nextval('transactions_transaction_id_seq');
    
    -- Check if cryptos are stablecoins
    SELECT COALESCE(is_stablecoin, FALSE) INTO v_is_sell_stablecoin
    FROM crypto_prices WHERE symbol = p_crypto_sell;
    
    SELECT COALESCE(is_stablecoin, FALSE) INTO v_is_buy_stablecoin
    FROM crypto_prices WHERE symbol = p_crypto_buy;
    
    -- Calculate price_per_unit intelligently based on whether they're stablecoins
    IF v_is_sell_stablecoin THEN
        -- Selling stablecoin: use 1.0 as the price for the stablecoin
        v_sell_price_per_unit := 1.00;
        -- Buying crypto: price is how much stablecoin per unit of crypto bought
        v_buy_price_per_unit := p_amount_sell / NULLIF(p_amount_buy, 0);
    ELSIF v_is_buy_stablecoin THEN
        -- Buying stablecoin: use 1.0 as the price for the stablecoin
        v_buy_price_per_unit := 1.00;
        -- Selling crypto: price is how much stablecoin per unit of crypto sold
        v_sell_price_per_unit := p_amount_buy / NULLIF(p_amount_sell, 0);
    ELSE
        -- Neither is stablecoin: use exchange rate between them
        v_buy_price_per_unit := p_amount_sell / NULLIF(p_amount_buy, 0);
        v_sell_price_per_unit := p_amount_buy / NULLIF(p_amount_sell, 0);
    END IF;
    
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
        v_date_cr,
        'BUY',
        p_crypto_buy,
        p_amount_buy,
        v_buy_price_per_unit,
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
        v_date_cr,
        'SELL',
        p_crypto_sell,
        p_amount_sell,
        v_sell_price_per_unit,
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

-- Step 4: Helper function to add new cryptos with stablecoin flag
CREATE OR REPLACE FUNCTION add_crypto_price(
    p_symbol VARCHAR(20),
    p_name VARCHAR(100),
    p_current_price DECIMAL(18, 8),
    p_is_stablecoin BOOLEAN DEFAULT FALSE
)
RETURNS INT AS $$
DECLARE
    v_crypto_id INT;
BEGIN
    INSERT INTO crypto_prices (symbol, name, current_price, is_stablecoin)
    VALUES (p_symbol, p_name, p_current_price, p_is_stablecoin)
    ON CONFLICT (symbol) DO UPDATE 
    SET 
        name = EXCLUDED.name,
        current_price = EXCLUDED.current_price,
        is_stablecoin = EXCLUDED.is_stablecoin,
        last_updated = (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica')
    RETURNING crypto_id INTO v_crypto_id;
    
    RETURN v_crypto_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: TRANSFER IN (deposit from external wallet/exchange)
CREATE OR REPLACE FUNCTION transfer_in(
    p_portfolio_id INT,
    p_date TIMESTAMPTZ,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_cost_basis DECIMAL(18, 8) DEFAULT 0, -- Optional: what you originally paid for it
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
    v_date_cr TIMESTAMPTZ;
BEGIN
    -- Ensure date is in Costa Rica timezone
    v_date_cr := p_date AT TIME ZONE 'America/Costa_Rica';
    
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
        v_date_cr,
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
    p_date TIMESTAMPTZ,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
    v_current_balance DECIMAL(18, 8);
    v_date_cr TIMESTAMPTZ;
BEGIN
    -- Ensure date is in Costa Rica timezone
    v_date_cr := p_date AT TIME ZONE 'America/Costa_Rica';
    
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
        v_date_cr,
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
    p_date TIMESTAMPTZ,
    p_crypto VARCHAR(20),
    p_amount DECIMAL(18, 8),
    p_price_per_unit DECIMAL(18, 8),
    p_fee DECIMAL(18, 8) DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_transaction_id INT;
    v_date_cr TIMESTAMPTZ;
BEGIN
    -- Ensure date is in Costa Rica timezone
    v_date_cr := p_date AT TIME ZONE 'America/Costa_Rica';
    
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
        v_date_cr,
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
    p_date TIMESTAMPTZ,
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
    v_date_cr TIMESTAMPTZ;
BEGIN
    -- Ensure date is in Costa Rica timezone
    v_date_cr := p_date AT TIME ZONE 'America/Costa_Rica';
    
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
        v_date_cr,
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

-- View: Transaction History with Trade Pairing (showing timestamps in Costa Rica time)
CREATE OR REPLACE VIEW v_transaction_history AS
SELECT 
    t.transaction_id,
    t.transaction_date AT TIME ZONE 'America/Costa_Rica' AS transaction_date_cr,
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
    t.created_at AT TIME ZONE 'America/Costa_Rica' AS created_at_cr
FROM transactions t
JOIN portfolios p ON t.portfolio_id = p.portfolio_id
ORDER BY t.transaction_date DESC, t.transaction_id DESC;

-- ============================================
-- 6. USAGE EXAMPLES
-- ============================================

-- Example: Using current Costa Rica time
/*
SELECT * FROM execute_trade(
    p_portfolio_id := 1,
    p_date := (CURRENT_TIMESTAMP AT TIME ZONE 'America/Costa_Rica'),
    p_crypto_buy := 'BTC',
    p_amount_buy := 0.01,
    p_crypto_sell := 'USDT',
    p_amount_sell := 430,
    p_fee := 0.43,
    p_fee_crypto := 'USDT',
    p_notes := 'Buy BTC with USDT'
);
*/

-- Example: Specifying a specific Costa Rica date/time
/*
SELECT buy_with_fiat(
    p_portfolio_id := 1,
    p_date := '2025-01-02 10:30:00-06'::TIMESTAMPTZ, -- -06 is Costa Rica UTC offset
    p_crypto := 'ETH',
    p_amount := 10,
    p_price_per_unit := 2900,
    p_fee := 5,
    p_notes := 'Morning DCA purchase'
);
*/

-- View all transactions with Costa Rica timestamps
/*
SELECT 
    transaction_id,
    transaction_date_cr,
    transaction_type,
    crypto_symbol,
    amount,
    portfolio_name
FROM v_transaction_history
LIMIT 10;
*/

-- ============================================
-- View: Position Size Metrics by ATR
-- Calculates position sizing metric based on volatility
-- ============================================

CREATE OR REPLACE VIEW v_position_size_metrics AS
SELECT 
    h.portfolio_id,
    h.portfolio_name,
    h.crypto_symbol,
    cp.name AS crypto_name,
    h.total_amount,
    h.current_value,
    h.total_cost,
    h.profit_loss,
    h.profit_loss_percent,
    cp.current_price,
    cp.atr_30,
    cp.is_stablecoin,
    -- Position size metric: (current_value * 0.01) / atr_30
    CASE 
        WHEN cp.atr_30 IS NOT NULL AND cp.atr_30 > 0 THEN
            (h.current_value * 0.01) / cp.atr_30
        ELSE 
            NULL
    END AS position_size_metric,
    -- Additional context: what percentage of portfolio this represents
    (h.current_value / NULLIF(ps.current_value, 0)) * 100 AS portfolio_weight_percent,
    -- Risk score: higher values indicate larger position relative to volatility
    CASE 
        WHEN cp.atr_30 IS NOT NULL AND cp.atr_30 > 0 THEN
            CASE 
                WHEN (h.current_value * 0.01) / cp.atr_30 > 1.0 THEN 'HIGH'
                WHEN (h.current_value * 0.01) / cp.atr_30 > 0.5 THEN 'MEDIUM'
                ELSE 'LOW'
            END
        ELSE 
            'NO_ATR_DATA'
    END AS risk_level
FROM v_holdings h
JOIN crypto_prices cp ON h.crypto_symbol = cp.symbol
JOIN v_portfolio_summary ps ON h.portfolio_id = ps.portfolio_id
WHERE cp.atr_30 IS NOT NULL 
  AND cp.atr_30 > 0;