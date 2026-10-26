-- ============================================
-- 健身房会员管理系统- 建表脚本
-- OpenGauss 5.0 (PostgreSQL 兼容模式)
-- ============================================

-- 1. 会员表
CREATE TABLE IF NOT EXISTS member (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    gender SMALLINT DEFAULT 0,
    birthday DATE,
    avatar_url VARCHAR(500),
    status SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_member_phone ON member(phone);

-- 2. 会员卡类型表
CREATE TABLE IF NOT EXISTS card_template (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type SMALLINT NOT NULL DEFAULT 0,
    duration_days INT DEFAULT 0,
    total_count INT DEFAULT 0,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    status SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 会员持有卡表
CREATE TABLE IF NOT EXISTS member_card (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES member(id),
    template_id BIGINT NOT NULL REFERENCES card_template(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    remaining_count INT DEFAULT 0,
    status SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_member_card_member ON member_card(member_id);
CREATE INDEX idx_member_card_valid ON member_card(member_id, status);

-- 4. 续费记录表
CREATE TABLE IF NOT EXISTS renewal_record (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES member(id),
    card_id BIGINT NOT NULL REFERENCES member_card(id),
    template_id BIGINT NOT NULL REFERENCES card_template(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method SMALLINT DEFAULT 0,
    renewal_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_end_date DATE,
    new_end_date DATE NOT NULL,
    remark VARCHAR(255)
);
CREATE INDEX idx_renewal_member ON renewal_record(member_id);

-- 5. 教练表
CREATE TABLE IF NOT EXISTS coach (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL DEFAULT '"'"''"'"',
    specialty VARCHAR(200),
    avatar_url VARCHAR(500),
    status SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. 课程定义表
CREATE TABLE IF NOT EXISTS course (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    cover_url VARCHAR(500),
    max_capacity INT DEFAULT 20,
    duration_minutes INT DEFAULT 60,
    status SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. 排课表
CREATE TABLE IF NOT EXISTS course_schedule (
    id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES course(id),
    coach_id BIGINT NOT NULL REFERENCES coach(id),
    class_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    actual_capacity INT DEFAULT 20,
    booked_count INT DEFAULT 0,
    status SMALLINT DEFAULT 0,
    remark VARCHAR(200),
    version INT DEFAULT 0
);
CREATE INDEX idx_schedule_date ON course_schedule(class_date, status);
CREATE INDEX idx_schedule_coach ON course_schedule(coach_id, class_date);

-- 8. 预约记录表
CREATE TABLE IF NOT EXISTS booking (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES member(id),
    card_id BIGINT REFERENCES member_card(id),
    schedule_id BIGINT NOT NULL REFERENCES course_schedule(id),
    status SMALLINT DEFAULT 0,
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checked_in_at TIMESTAMP,
    cancelled_at TIMESTAMP
);
CREATE INDEX idx_booking_member ON booking(member_id, status);
CREATE INDEX idx_booking_schedule ON booking(schedule_id, status);

-- 9. 签到记录表
CREATE TABLE IF NOT EXISTS check_in (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES booking(id),
    member_id BIGINT NOT NULL REFERENCES member(id),
    schedule_id BIGINT NOT NULL REFERENCES course_schedule(id),
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method SMALLINT DEFAULT 0
);
CREATE INDEX idx_check_in_member ON check_in(member_id);
CREATE INDEX idx_check_in_date ON check_in(check_in_time);

-- ============================================
-- 插入测试数据
-- ============================================
INSERT INTO card_template (name, type, duration_days, total_count, price, status) VALUES
('月卡', 0, 30, 0, 299.00, 0),
('季卡', 0, 90, 0, 699.00, 0),
('年卡', 0, 365, 0, 1999.00, 0),
('次卡(10次)', 1, 180, 10, 399.00, 0),
('次卡(30次)', 1, 365, 30, 899.00, 0);

INSERT INTO coach (name, phone, password_hash, specialty, status) VALUES
('张伟', '13800138001', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '瑜伽/普拉提', 0),
('李娜', '13800138002', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '动感单车/有氧操', 0),
('王强', '13800138003', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '力量训练/私教', 0),
('赵丽', '13800138004', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '舞蹈/形体', 0);

INSERT INTO course (name, description, max_capacity, duration_minutes, status) VALUES
('流瑜伽', '通过流畅的体式衔接提升柔韧性于力量', 25, 60, 0),
('动感单车', '高强度燃脂骑行课程', 20, 45, 0),
('普拉提', '核心肌群训练，改善体态', 20, 60, 0),
('有氧搏击', '结合拳击动作的高效燃脂课程', 30, 50, 0);

INSERT INTO member (name, phone, password_hash, gender, birthday, status) VALUES
('测试会员', '13800000000', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 1, '1995-06-15', 0);

INSERT INTO member_card (member_id, template_id, start_date, end_date, remaining_count, status)
SELECT 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '"'"'30 days'"'"'', 0, 0;

INSERT INTO course_schedule (course_id, coach_id, class_date, start_time, end_time, actual_capacity, booked_count, status) VALUES
(1, 1, CURRENT_DATE, '09:00:00', '10:00:00', 25, 0, 0),
(2, 2, CURRENT_DATE, '14:00:00', '14:45:00', 20, 0, 0),
(3, 3, CURRENT_DATE + INTERVAL '1 day', '09:00:00', '10:00:00', 20, 0, 0),
(4, 4, CURRENT_DATE + INTERVAL '1 day', '18:00:00', '18:50:00', 30, 0, 0);