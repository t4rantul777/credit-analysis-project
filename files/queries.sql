-- =============================================
-- Схема БД: Обработка заявок на кредит
-- =============================================

CREATE TABLE clients (
    client_id   INTEGER PRIMARY KEY,
    full_name   TEXT NOT NULL,
    birth_date  DATE,
    credit_score INTEGER
);

CREATE TABLE applications (
    app_id      INTEGER PRIMARY KEY,
    client_id   INTEGER REFERENCES clients(client_id),
    amount      DECIMAL(12, 2),
    status      TEXT CHECK(status IN ('new', 'review', 'approved', 'rejected')),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP
);

CREATE TABLE decisions (
    decision_id INTEGER PRIMARY KEY,
    app_id      INTEGER REFERENCES applications(app_id),
    analyst_id  INTEGER,
    decision    TEXT CHECK(decision IN ('approve', 'reject')),
    reason      TEXT,
    decided_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Аналитические запросы
-- =============================================

-- 1. Количество заявок по статусам
SELECT
    status,
    COUNT(*) AS total
FROM applications
GROUP BY status
ORDER BY total DESC;

-- 2. Средняя сумма одобренных заявок
SELECT
    ROUND(AVG(a.amount), 2) AS avg_approved_amount
FROM applications a
JOIN decisions d ON a.app_id = d.app_id
WHERE d.decision = 'approve';

-- 3. Клиенты с кредитным рейтингом выше среднего и одобренными заявками
SELECT
    c.full_name,
    c.credit_score,
    a.amount,
    a.status
FROM clients c
JOIN applications a ON c.client_id = a.client_id
WHERE c.credit_score > (SELECT AVG(credit_score) FROM clients)
  AND a.status = 'approved'
ORDER BY c.credit_score DESC;

-- 4. Время обработки заявок (в часах)
SELECT
    a.app_id,
    a.status,
    ROUND(
        EXTRACT(EPOCH FROM (d.decided_at - a.created_at)) / 3600, 1
    ) AS hours_to_decision
FROM applications a
JOIN decisions d ON a.app_id = d.app_id
ORDER BY hours_to_decision DESC;

-- 5. Топ-3 причины отказа
SELECT
    reason,
    COUNT(*) AS cnt
FROM decisions
WHERE decision = 'reject'
GROUP BY reason
ORDER BY cnt DESC
LIMIT 3;

-- 6. Заявки без решения (зависшие в статусе review более 3 дней)
SELECT
    app_id,
    client_id,
    amount,
    created_at
FROM applications
WHERE status = 'review'
  AND created_at < NOW() - INTERVAL '3 days';
