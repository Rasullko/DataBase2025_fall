-- Task 0: Schema and sample data

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  iin CHAR(12) UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','blocked','frozen')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  daily_limit_kzt NUMERIC(20,2) DEFAULT 1000000
);

CREATE TABLE accounts (
  account_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  account_number TEXT UNIQUE NOT NULL,
  currency TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  balance NUMERIC(20,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE exchange_rates (
  rate_id SERIAL PRIMARY KEY,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate NUMERIC(18,8) NOT NULL,
  valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  valid_to TIMESTAMP WITH TIME ZONE
);

CREATE TABLE transactions (
  transaction_id BIGSERIAL PRIMARY KEY,
  from_account_id INT REFERENCES accounts(account_id),
  to_account_id INT REFERENCES accounts(account_id),
  amount NUMERIC(20,2) NOT NULL,
  currency TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  exchange_rate NUMERIC(18,8),
  amount_kzt NUMERIC(20,2),
  type TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
  status TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  description TEXT
);

CREATE TABLE audit_log (
  log_id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  record_id TEXT,
  action TEXT CHECK (action IN ('INSERT','UPDATE','DELETE','OTHER')),
  old_values JSONB,
  new_values JSONB,
  changed_by TEXT,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ip_address INET
);

INSERT INTO customers (iin, full_name, phone, email, status, created_at, daily_limit_kzt) VALUES
('880101123456','Aidar N.', '+77010000001','aidar@example.com','active',now()-interval '400 days',2000000),
('880102123457','Bekzat K.', '+77010000002','bekzat@example.com','active',now()-interval '300 days',1500000),
('880103123458','Dina S.', '+77010000003','dina@example.com','active',now()-interval '200 days',5000000),
('880104123459','Erlan T.', '+77010000004','erlan@example.com','frozen',now()-interval '100 days',1000000),
('880105123460','Gulzar M.', '+77010000005','gulzar@example.com','blocked',now()-interval '90 days',1000000),
('880106123461','Ilyas B.', '+77010000006','ilyas@example.com','active',now()-interval '60 days',2000000),
('880107123462','Kamilya Z.','+77010000007','kamilya@example.com','active',now()-interval '45 days',1200000),
('880108123463','Marat O.','+77010000008','marat@example.com','active',now()-interval '30 days',1000000),
('880109123464','Nurzhan P.','+77010000009','nurzhan@example.com','active',now()-interval '20 days',3000000),
('880110123465','Olzhas Q.','+77010000010','olzhas@example.com','active',now()-interval '10 days',800000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active, opened_at) VALUES
(1,'KZ01AIDAR0000001','KZT',1000000,TRUE,now()-interval '300 days'),
(1,'KZ01AIDARUSD01','USD',2000,TRUE,now()-interval '300 days'),
(2,'KZ02BEKZ0000002','KZT',500000,TRUE,now()-interval '200 days'),
(3,'KZ03DINA000003','EUR',800,TRUE,now()-interval '200 days'),
(4,'KZ04ERLAN00004','KZT',10000,TRUE,now()-interval '100 days'),
(5,'KZ05GULZ000005','RUB',50000,TRUE,now()-interval '90 days'),
(6,'KZ06ILYAS00006','KZT',2500000,TRUE,now()-interval '60 days'),
(7,'KZ07KAMI000007','USD',1500,TRUE,now()-interval '45 days'),
(8,'KZ08MARAT00008','KZT',750000,TRUE,now()-interval '30 days'),
(9,'KZ09NURZ000009','KZT',300000,TRUE,now()-interval '20 days');

INSERT INTO exchange_rates (from_currency,to_currency,rate,valid_from,valid_to) VALUES
('USD','KZT',470.00,now()-interval '10 days',NULL),
('EUR','KZT',510.00,now()-interval '10 days',NULL),
('RUB','KZT',5.50,now()-interval '10 days',NULL),
('KZT','USD',0.00212766,now()-interval '10 days',NULL),
('KZT','EUR',0.00196078,now()-interval '10 days',NULL),
('USD','EUR',0.921,now()-interval '10 days',NULL),
('EUR','USD',1.085,now()-interval '10 days',NULL),
('RUB','USD',0.012,now()-interval '10 days',NULL),
('USD','RUB',83.33,now()-interval '10 days',NULL),
('RUB','EUR',0.0109,now()-interval '10 days',NULL);

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description) VALUES
(1,3,10000,'KZT',1,10000,'transfer','completed',now()-interval '7 days',now()-interval '7 days','Internal test'),
(2,4,100,'USD',470,47000,'transfer','completed',now()-interval '6 days',now()-interval '6 days','USD to EUR example'),
(NULL,1,50000,'KZT',1,50000,'deposit','completed',now()-interval '5 days',now()-interval '5 days','Cash deposit'),
(6,9,100000,'KZT',1,100000,'transfer','completed',now()-interval '4 days',now()-interval '4 days','Salary prepayment'),
(7,2,200,'USD',470,94000,'transfer','completed',now()-interval '3 days',now()-interval '3 days','Payment'),
(5,8,10000,'RUB',5.5,55000,'transfer','completed',now()-interval '2 days',now()-interval '2 days','RUB transfer'),
(1,9,30000,'KZT',1,30000,'transfer','completed',now()-interval '1 day',now()-interval '1 day','Gift'),
(3,6,50,'EUR',510,25500,'transfer','completed',now()-interval '12 hours',now()-interval '11 hours','Convert EUR to KZT'),
(8,4,120000,'KZT',1,120000,'withdrawal','completed',now()-interval '2 hours',now()-interval '2 hours','ATM'),
(9,7,25000,'KZT',1,25000,'transfer','pending',now()-interval '1 hour',NULL,'Pending transfer');

-- Task 1: process_transfer

CREATE OR REPLACE FUNCTION log_audit(
  p_table TEXT,
  p_record TEXT,
  p_action TEXT,
  p_old JSONB,
  p_new JSONB,
  p_user TEXT,
  p_ip INET
) RETURNS VOID AS $$
BEGIN
  INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by, ip_address)
  VALUES (p_table, p_record, p_action, p_old, p_new, p_user, p_ip);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_rate(p_from TEXT, p_to TEXT) RETURNS NUMERIC AS $$
DECLARE
  r NUMERIC;
BEGIN
  IF p_from = p_to THEN
    RETURN 1;
  END IF;

  SELECT rate INTO r
  FROM exchange_rates
  WHERE from_currency = p_from
    AND to_currency = p_to
    AND (valid_to IS NULL OR valid_to > now())
  ORDER BY valid_from DESC
  LIMIT 1;

  IF r IS NULL THEN
    RAISE EXCEPTION 'NO_RATE_AVAILABLE' USING ERRCODE = 'P0001';
  END IF;

  RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE process_transfer(
  p_from_account_number TEXT,
  p_to_account_number TEXT,
  p_amount NUMERIC,
  p_currency TEXT,
  p_description TEXT,
  p_initiator TEXT DEFAULT 'system',
  p_ip INET DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_from_account RECORD;
  v_to_account RECORD;
  v_amount_kzt NUMERIC;
  v_rate NUMERIC;
  v_sender_daily_limit NUMERIC;
  v_today_sum NUMERIC;
  v_tx BIGINT;
BEGIN
  IF p_amount <= 0 THEN
    PERFORM log_audit('transactions', NULL, 'OTHER', NULL,
      jsonb_build_object('error','invalid_amount','amount',p_amount),
      p_initiator, p_ip);
    RAISE EXCEPTION 'INVALID_AMOUNT' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_from_account FROM accounts WHERE account_number = p_from_account_number;
  IF NOT FOUND THEN
    PERFORM log_audit('accounts', NULL, 'OTHER', NULL,
      jsonb_build_object('error','from_account_not_found','acc',p_from_account_number),
      p_initiator, p_ip);
    RAISE EXCEPTION 'FROM_ACCOUNT_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_to_account FROM accounts WHERE account_number = p_to_account_number;
  IF NOT FOUND THEN
    PERFORM log_audit('accounts', v_from_account.account_id::TEXT, 'OTHER', NULL,
      jsonb_build_object('error','to_account_not_found','acc',p_to_account_number),
      p_initiator, p_ip);
    RAISE EXCEPTION 'TO_ACCOUNT_NOT_FOUND' USING ERRCODE = 'P0003';
  END IF;

  IF NOT v_from_account.is_active OR NOT v_to_account.is_active THEN
    PERFORM log_audit('accounts', v_from_account.account_id::TEXT, 'OTHER', NULL,
      jsonb_build_object('error','inactive_account'),
      p_initiator, p_ip);
    RAISE EXCEPTION 'ACCOUNT_INACTIVE' USING ERRCODE = 'P0004';
  END IF;

  IF (SELECT status FROM customers WHERE customer_id = v_from_account.customer_id) <> 'active' THEN
    PERFORM log_audit('customers', v_from_account.customer_id::TEXT, 'OTHER', NULL,
      jsonb_build_object('error','customer_not_active'),
      p_initiator, p_ip);
    RAISE EXCEPTION 'SENDER_NOT_ACTIVE' USING ERRCODE = 'P0006';
  END IF;

  PERFORM pg_advisory_xact_lock(v_from_account.account_id);
  PERFORM pg_advisory_xact_lock(v_to_account.account_id);

  SELECT 1 FROM accounts
  WHERE account_id IN (v_from_account.account_id, v_to_account.account_id)
  FOR UPDATE;

  v_rate := get_rate(p_currency, 'KZT');
  v_amount_kzt := round(p_amount * v_rate, 2);

  IF v_from_account.currency = p_currency THEN
    IF v_from_account.balance < p_amount THEN
      PERFORM log_audit('accounts', v_from_account.account_id::TEXT, 'OTHER',
        jsonb_build_object('balance',v_from_account.balance),
        jsonb_build_object('attempt',p_amount),
        p_initiator, p_ip);
      RAISE EXCEPTION 'INSUFFICIENT_FUNDS' USING ERRCODE = 'P0007';
    END IF;
  ELSE
    DECLARE v_rate_sender NUMERIC := get_rate(p_currency, v_from_account.currency);
    IF v_from_account.balance < (p_amount * v_rate_sender) THEN
      PERFORM log_audit('accounts', v_from_account.account_id::TEXT, 'OTHER',
        jsonb_build_object('balance',v_from_account.balance),
        jsonb_build_object('attempt',p_amount,'in_currency',p_currency),
        p_initiator, p_ip);
      RAISE EXCEPTION 'INSUFFICIENT_FUNDS_CURRENCY' USING ERRCODE = 'P0008';
    END IF;
  END IF;

  SELECT daily_limit_kzt INTO v_sender_daily_limit
  FROM customers WHERE customer_id = v_from_account.customer_id;

  SELECT COALESCE(SUM(amount_kzt),0)
  INTO v_today_sum
  FROM transactions t
  JOIN accounts a ON t.from_account_id = a.account_id
  WHERE a.customer_id = v_from_account.customer_id
    AND t.created_at::date = now()::date
    AND t.status IN ('completed','pending','salary');

  IF (v_today_sum + v_amount_kzt) > v_sender_daily_limit THEN
    PERFORM log_audit('transactions', NULL, 'OTHER', NULL,
      jsonb_build_object('error','daily_limit_exceeded','today_sum',v_today_sum,'attempt_kzt',v_amount_kzt,'limit',v_sender_daily_limit),
      p_initiator, p_ip);
    RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED' USING ERRCODE = 'P0009';
  END IF;

  INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,description)
  VALUES (v_from_account.account_id, v_to_account.account_id, p_amount, p_currency, v_rate, v_amount_kzt, 'transfer', 'pending', now(), p_description)
  RETURNING transaction_id INTO v_tx;

  IF v_from_account.currency = p_currency THEN
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_account.account_id;
  ELSE
    DECLARE v_rate_to_sender NUMERIC := get_rate(p_currency, v_from_account.currency);
    UPDATE accounts
    SET balance = balance - round(p_amount * v_rate_to_sender, 2)
    WHERE account_id = v_from_account.account_id;
  END IF;

  IF v_to_account.currency = p_currency THEN
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to_account.account_id;
  ELSE
    DECLARE v_rate_to_receiver NUMERIC := get_rate(p_currency, v_to_account.currency);
    UPDATE accounts
    SET balance = balance + round(p_amount * v_rate_to_receiver, 2)
    WHERE account_id = v_to_account.account_id;
  END IF;

  UPDATE transactions SET status='completed', completed_at=now() WHERE transaction_id = v_tx;

  PERFORM log_audit('accounts', v_from_account.account_id::TEXT, 'UPDATE',
    jsonb_build_object('balance', v_from_account.balance),
    (SELECT to_jsonb(a) FROM accounts a WHERE a.account_id = v_from_account.account_id),
    p_initiator, p_ip);

  PERFORM log_audit('accounts', v_to_account.account_id::TEXT, 'UPDATE',
    NULL,
    (SELECT to_jsonb(a) FROM accounts a WHERE a.account_id = v_to_account.account_id),
    p_initiator, p_ip);

  PERFORM log_audit('transactions', v_tx::TEXT, 'INSERT',
    NULL,
    (SELECT to_jsonb(t) FROM transactions t WHERE t.transaction_id = v_tx),
    p_initiator, p_ip);
END;
$$;

-- Task 2: Views

-- View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
  c.customer_id,
  c.full_name,
  c.iin,
  c.email,
  a.account_id,
  a.account_number,
  a.currency,
  a.balance,
  round(
    a.balance *
    COALESCE(
      (SELECT rate
       FROM exchange_rates er
       WHERE er.from_currency = a.currency
         AND er.to_currency = 'KZT'
         AND (er.valid_to IS NULL OR er.valid_to > now())
       ORDER BY er.valid_from DESC
       LIMIT 1),
      1
    ), 2
  ) AS balance_kzt,
  round(
    SUM(
      a.balance *
      COALESCE(
        (SELECT rate
         FROM exchange_rates er
         WHERE er.from_currency = a.currency
           AND er.to_currency = 'KZT'
           AND (er.valid_to IS NULL OR er.valid_to > now())
         ORDER BY er.valid_from DESC
         LIMIT 1),
        1
      )
    ) OVER (PARTITION BY c.customer_id)
  ,2) AS total_balance_kzt,
  c.daily_limit_kzt,
  round(
    (
      SUM(
        a.balance *
        COALESCE(
          (SELECT rate
           FROM exchange_rates er
           WHERE er.from_currency = a.currency
             AND er.to_currency = 'KZT'
             AND (er.valid_to IS NULL OR er.valid_to > now())
           ORDER BY er.valid_from DESC
           LIMIT 1),
          1
        )
      ) OVER (PARTITION BY c.customer_id)
      / NULLIF(c.daily_limit_kzt,0)
    ) * 100,
 2) AS daily_limit_utilization_pct,
  RANK() OVER (
    ORDER BY
      SUM(
        a.balance *
        COALESCE(
          (SELECT rate
           FROM exchange_rates er
           WHERE er.from_currency = a.currency
             AND er.to_currency = 'KZT'
             AND (er.valid_to IS NULL OR er.valid_to > now())
           ORDER BY er.valid_from DESC
           LIMIT 1),
          1
        )
      ) OVER (PARTITION BY c.customer_id) DESC
  ) AS balance_rank
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
WHERE a.is_active = TRUE;


-- View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
  t_day,
  type,
  SUM(total_volume) AS total_volume,
  SUM(tx_count) AS tx_count,
  ROUND(AVG(avg_amount),2) AS avg_amount,
  SUM(SUM(total_volume)) OVER (
    ORDER BY t_day
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_volume,
  LAG(SUM(total_volume)) OVER (ORDER BY t_day) AS prev_day_total,
  CASE
    WHEN LAG(SUM(total_volume)) OVER (ORDER BY t_day) IS NULL THEN NULL
    WHEN LAG(SUM(total_volume)) OVER (ORDER BY t_day) = 0 THEN NULL
    ELSE ROUND(
      (SUM(total_volume) - LAG(SUM(total_volume)) OVER (ORDER BY t_day))
      / LAG(SUM(total_volume)) OVER (ORDER BY t_day) * 100,
      2
    )
  END AS day_over_day_pct
FROM (
  SELECT
    date_trunc('day', created_at) AS t_day,
    type,
    SUM(amount_kzt) AS total_volume,
    COUNT(*) AS tx_count,
    AVG(amount_kzt) AS avg_amount
  FROM transactions
  WHERE created_at IS NOT NULL
  GROUP BY 1,2
) s
GROUP BY t_day, type
ORDER BY t_day DESC, type;


-- View 3: suspicious_activity_view
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT
  t.transaction_id,
  t.from_account_id,
  t.to_account_id,
  t.amount,
  t.currency,
  t.amount_kzt,
  t.created_at,
  t.status,
  (t.amount_kzt > 5000000) AS over_5m_kzt,
  c_cnt.tx_count_hour,
  seq.seq_count
FROM transactions t
LEFT JOIN LATERAL (
  SELECT
    COUNT(*) FILTER (
      WHERE t2.created_at >= t.created_at - interval '1 hour'
        AND t2.created_at <= t.created_at + interval '1 hour'
    ) AS tx_count_hour
  FROM transactions t2
  JOIN accounts a2 ON t2.from_account_id = a2.account_id
  WHERE a2.customer_id = (
    SELECT customer_id FROM accounts WHERE account_id = t.from_account_id
  )
) c_cnt ON true
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS seq_count
  FROM transactions t3
  WHERE t3.from_account_id = t.from_account_id
    AND t3.created_at >= t.created_at - interval '1 minute'
    AND t3.created_at <= t.created_at + interval '1 minute'
) seq ON true
WHERE
  (t.amount_kzt > 5000000)
  OR (c_cnt.tx_count_hour > 10)
  OR (seq.seq_count > 3);

-- Task 3: Indexes and performance optimization

-- B-tree composite index
CREATE INDEX IF NOT EXISTS idx_accounts_customer_currency
ON accounts (customer_id, currency);

-- Hash index on status
CREATE INDEX IF NOT EXISTS idx_transactions_status_hash
ON transactions USING HASH (status);

-- GIN indexes on JSONB fields
CREATE INDEX IF NOT EXISTS idx_auditlog_old_gin
ON audit_log USING GIN (old_values);

CREATE INDEX IF NOT EXISTS idx_auditlog_new_gin
ON audit_log USING GIN (new_values);

-- Partial covering index for active accounts
CREATE INDEX IF NOT EXISTS idx_accounts_active_partial
ON accounts (account_number, balance)
WHERE is_active = true;

-- Expression index for case-insensitive email search
CREATE INDEX IF NOT EXISTS idx_customers_email_lower
ON customers (lower(email));

-- Covering index for frequent transaction lookups
CREATE INDEX IF NOT EXISTS idx_transactions_from_created_covering
ON transactions (from_account_id, created_at)
INCLUDE (amount, amount_kzt, status);

-- BRIN index for large datasets (time-series)
CREATE INDEX IF NOT EXISTS idx_transactions_created_brin
ON transactions USING BRIN (created_at);

-- EXPLAIN ANALYZE queries
EXPLAIN ANALYZE
SELECT * FROM accounts WHERE account_number = 'KZ01AIDAR0000001';

EXPLAIN ANALYZE
SELECT * FROM customers WHERE lower(email) = 'aidar@example.com';

EXPLAIN ANALYZE
SELECT from_account_id, SUM(amount_kzt)
FROM transactions
WHERE created_at > now() - interval '7 days'
GROUP BY from_account_id;

EXPLAIN ANALYZE
SELECT * FROM audit_log
WHERE new_values @> '{"status":"completed"}';

-- Task 4: Batch salary processing

CREATE OR REPLACE PROCEDURE process_salary_batch(
  p_company_account_number TEXT,
  p_payments JSONB,
  OUT successful_count INT,
  OUT failed_count INT,
  OUT failed_details JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_company_account RECORD;
  v_lock_key BIGINT;
  v_row JSONB;
  v_iin TEXT;
  v_amount NUMERIC;
  v_desc TEXT;
  v_customer RECORD;
  v_emp_account RECORD;
  v_idx INT := 0;
  v_success INT := 0;
  v_fail INT := 0;
  v_fail_list JSONB := '[]';
  v_total NUMERIC := 0;
  v_tx BIGINT;
BEGIN
  successful_count := 0;
  failed_count := 0;
  failed_details := '[]';

  SELECT * INTO v_company_account
  FROM accounts
  WHERE account_number = p_company_account_number;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COMPANY_ACCOUNT_NOT_FOUND' USING ERRCODE = 'P1001';
  END IF;

  v_lock_key := v_company_account.account_id;
  PERFORM pg_advisory_lock(v_lock_key);

  FOR v_row IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
    v_idx := v_idx + 1;
    v_amount := (v_row->>'amount')::NUMERIC;

    IF v_amount IS NULL OR v_amount <= 0 THEN
      v_fail := v_fail + 1;
      v_fail_list := v_fail_list || jsonb_build_object(
        'index', v_idx,
        'reason', 'invalid_amount',
        'row', v_row
      );
      CONTINUE;
    END IF;

    v_total := v_total + v_amount;
  END LOOP;

  IF v_total > v_company_account.balance THEN
    PERFORM log_audit(
      'accounts',
      v_company_account.account_id::TEXT,
      'OTHER',
      to_jsonb(v_company_account),
      jsonb_build_object(
        'error', 'insufficient_company_funds',
        'required', v_total,
        'available', v_company_account.balance
      ),
      'system',
      NULL
    );
    PERFORM pg_advisory_unlock(v_lock_key);
    RAISE EXCEPTION 'COMPANY_INSUFFICIENT_FUNDS' USING ERRCODE = 'P1002';
  END IF;

  CREATE TEMP TABLE tmp_updates (account_id INT, delta NUMERIC) ON COMMIT DROP;

  v_idx := 0;

  FOR v_row IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
    v_idx := v_idx + 1;

    BEGIN
      v_iin := v_row->>'iin';
      v_amount := (v_row->>'amount')::NUMERIC;
      v_desc := COALESCE(v_row->>'description','salary');

      IF v_amount IS NULL OR v_amount <= 0 THEN
        v_fail := v_fail + 1;
        v_fail_list := v_fail_list || jsonb_build_object(
          'index', v_idx,
          'reason', 'invalid_amount',
          'row', v_row
        );
        CONTINUE;
      END IF;

      SELECT * INTO v_customer
      FROM customers
      WHERE iin = v_iin;

      IF NOT FOUND THEN
        v_fail := v_fail + 1;
        v_fail_list := v_fail_list || jsonb_build_object(
          'index', v_idx,
          'reason', 'employee_not_found',
          'iin', v_iin
        );
        CONTINUE;
      END IF;

      SELECT * INTO v_emp_account
      FROM accounts
      WHERE customer_id = v_customer.customer_id
        AND currency = 'KZT'
        AND is_active = TRUE
      LIMIT 1;

      IF NOT FOUND THEN
        v_fail := v_fail + 1;
        v_fail_list := v_fail_list || jsonb_build_object(
          'index', v_idx,
          'reason', 'no_kzt_account',
          'iin', v_iin
        );
        CONTINUE;
      END IF;

      INSERT INTO transactions (
        from_account_id,
        to_account_id,
        amount,
        currency,
        exchange_rate,
        amount_kzt,
        type,
        status,
        created_at,
        description
      )
      VALUES (
        v_company_account.account_id,
        v_emp_account.account_id,
        v_amount,
        'KZT',
        1,
        v_amount,
        'salary',
        'pending',
        now(),
        v_desc
      )
      RETURNING transaction_id INTO v_tx;

      INSERT INTO tmp_updates VALUES (v_company_account.account_id, -(v_amount));
      INSERT INTO tmp_updates VALUES (v_emp_account.account_id, v_amount);

      v_success := v_success + 1;

    EXCEPTION WHEN OTHERS THEN
      v_fail := v_fail + 1;
      v_fail_list := v_fail_list || jsonb_build_object(
        'index', v_idx,
        'reason', 'exception',
        'message', SQLERRM
      );
      CONTINUE;
    END;
  END LOOP;

  CREATE TEMP TABLE tmp_final AS
  SELECT account_id, SUM(delta) AS delta_sum
  FROM tmp_updates
  GROUP BY account_id;

  UPDATE accounts a
  SET balance = a.balance + t.delta_sum
  FROM tmp_final t
  WHERE a.account_id = t.account_id;

  UPDATE transactions
  SET status='completed', completed_at=now()
  WHERE type='salary'
    AND status='pending'
    AND created_at >= now() - interval '10 minutes';

  PERFORM log_audit(
    'transactions',
    NULL,
    'OTHER',
    NULL,
    jsonb_build_object('action','salary_batch'),
    'system',
    NULL
  );

  successful_count := v_success;
  failed_count := v_fail;
  failed_details := v_fail_list;

  PERFORM pg_advisory_unlock(v_lock_key);
END;
$$;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(*) FILTER (WHERE type='salary' AND status='completed') AS completed_count,
  SUM(amount_kzt) FILTER (WHERE type='salary' AND status='completed') AS total_paid_kzt
FROM transactions
GROUP BY 1
ORDER BY 1 DESC;
