-- ============================================================================
-- NEWS PLATFORM DATABASE: FULL SCHEMA (DDL) & SEED DATA (DML)
-- Compatible with SQLite (DBeaver)
-- ============================================================================

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS advertisements;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS author_subscriptions;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS article_interactions;
DROP TABLE IF EXISTS article_media;
DROP TABLE IF EXISTS article_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS subscription_plans;
DROP TABLE IF EXISTS user_preferred_categories;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;

-- ============================================================================
-- PART 1: TABLE DEFINITIONS (DDL)
-- ============================================================================

-- 1. Users & Roles (RBAC)
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('READER', 'JOURNALIST', 'ADMIN')),
    is_banned BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. User Profiles (1:1 relationship with users)
CREATE TABLE user_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(150) NOT NULL,
    bio TEXT,
    avatar_url VARCHAR(500)
);

-- 3. Categories Hierarchy (Composite Pattern: self-referencing FK)
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL
);

-- 4. User Preferred Categories (M:N for PersonalizedFeedStrategy)
CREATE TABLE user_preferred_categories (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, category_id)
);

-- 5. Subscription Plans
CREATE TABLE subscription_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    price REAL NOT NULL,
    duration_days INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1
);

-- 6. User Subscriptions (State Pattern: ACTIVE, EXPIRED, CANCELLED)
CREATE TABLE subscriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'EXPIRED', 'CANCELLED')),
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL
);

-- 7. Articles (Builder Pattern)
CREATE TABLE articles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    author_id INTEGER NOT NULL REFERENCES users(id),
    category_id INTEGER NOT NULL REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    summary TEXT NOT NULL,
    content TEXT NOT NULL,
    is_premium BOOLEAN NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL CHECK (status IN ('DRAFT', 'PUBLISHED')),
    published_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tags & Article Tags (M:N)
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE article_tags (
    article_id INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);

-- 9. Article Media Attachments (1:N with articles)
CREATE TABLE article_media (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    media_url VARCHAR(500) NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO')),
    caption VARCHAR(255)
);

-- 10. Article Interactions (Likes, Bookmarks, Views)
CREATE TABLE article_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    is_liked BOOLEAN NOT NULL DEFAULT 0,
    is_bookmarked BOOLEAN NOT NULL DEFAULT 0,
    viewed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, article_id)
);

-- 11. Comments
CREATE TABLE comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. Author Subscriptions (Observer Pattern: Reader -> Journalist)
CREATE TABLE author_subscriptions (
    subscriber_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (subscriber_id, author_id)
);

-- 13. Notifications (Factory Method Pattern: EMAIL / PUSH)
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('EMAIL', 'PUSH')),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 14. Advertisements (Shown to Guests and Free-Tier Readers)
CREATE TABLE advertisements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    advertiser_name VARCHAR(120) NOT NULL,
    title VARCHAR(200) NOT NULL,
    banner_url VARCHAR(500) NOT NULL,
    target_url VARCHAR(500) NOT NULL,
    placement VARCHAR(30) NOT NULL CHECK (placement IN ('TOP_BANNER', 'SIDEBAR', 'IN_ARTICLE')),
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    impressions_count INTEGER NOT NULL DEFAULT 0,
    clicks_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL
);

-- ============================================================================
-- PART 2: SEED DATA (DML)
-- ============================================================================

-- 1. USERS (1-2: Admins, 3-6: Journalists, 7-12: Readers)
INSERT INTO users (email, password_hash, role, is_banned, created_at) VALUES
('alex.mercer@newsplatform.com', '$2a$10$hash_admin_01', 'ADMIN', FALSE, '2026-01-10 08:00:00'),
('claire.vance@newsplatform.com', '$2a$10$hash_admin_02', 'ADMIN', FALSE, '2026-01-12 09:15:00'),
('david.chen@newsplatform.com', '$2a$10$hash_jour_01', 'JOURNALIST', FALSE, '2026-01-15 10:30:00'),
('sarah.jenkins@newsplatform.com', '$2a$10$hash_jour_02', 'JOURNALIST', FALSE, '2026-01-18 11:00:00'),
('marcus.thorne@newsplatform.com', '$2a$10$hash_jour_03', 'JOURNALIST', FALSE, '2026-02-01 14:20:00'),
('elena.rostova@newsplatform.com', '$2a$10$hash_jour_04', 'JOURNALIST', FALSE, '2026-02-05 16:45:00'),
('liam.oconnor@gmail.com', '$2a$10$hash_read_01', 'READER', FALSE, '2026-03-01 12:00:00'),
('sophia.martinez@gmail.com', '$2a$10$hash_read_02', 'READER', FALSE, '2026-03-14 18:10:00'),
('noah.williams@outlook.com', '$2a$10$hash_read_03', 'READER', FALSE, '2026-04-02 09:40:00'),
('emma.davis@yahoo.com', '$2a$10$hash_read_04', 'READER', FALSE, '2026-05-19 20:15:00'),
('ethan.brown@gmail.com', '$2a$10$hash_read_05', 'READER', FALSE, '2026-06-22 13:50:00'),
('spam.bot99@mail.com', '$2a$10$hash_read_06', 'READER', TRUE, '2026-07-08 03:12:00');

-- 2. USER PROFILES
INSERT INTO user_profiles (user_id, full_name, bio, avatar_url) VALUES
(1, 'Alex Mercer', 'Chief Platform Administrator & Editorial Lead', 'https://ui-avatars.com/api/?name=Alex+Mercer&background=0D8ABC&color=fff&size=256'),
(2, 'Claire Vance', 'Content Moderator & Community Operations Manager', 'https://ui-avatars.com/api/?name=Claire+Vance&background=6366F1&color=fff&size=256'),
(3, 'David Chen', 'Senior Technology Correspondent covering AI, computer vision, and rendering pipelines.', 'https://ui-avatars.com/api/?name=David+Chen&background=10B981&color=fff&size=256'),
(4, 'Sarah Jenkins', 'Cybersecurity Analyst and Investigative Tech Journalist.', 'https://ui-avatars.com/api/?name=Sarah+Jenkins&background=F59E0B&color=fff&size=256'),
(5, 'Marcus Thorne', 'Financial Markets Editor & Venture Capital Columnist.', 'https://ui-avatars.com/api/?name=Marcus+Thorne&background=EF4444&color=fff&size=256'),
(6, 'Elena Rostova', 'Sports & Space Exploration Reporter.', 'https://ui-avatars.com/api/?name=Elena+Rostova&background=8B5CF6&color=fff&size=256'),
(7, 'Liam O''Connor', 'Software architect passionate about AI and cloud infrastructure.', 'https://ui-avatars.com/api/?name=Liam+OConnor&background=14B8A6&color=fff&size=256'),
(8, 'Sophia Martinez', 'Fintech product manager and avid macroeconomics reader.', 'https://ui-avatars.com/api/?name=Sophia+Martinez&background=EC4899&color=fff&size=256'),
(9, 'Noah Williams', 'Formula 1 enthusiast and weekend football fan.', NULL),
(10, 'Emma Davis', 'Astrophysics student following deep-space missions.', 'https://ui-avatars.com/api/?name=Emma+Davis&background=3B82F6&color=fff&size=256'),
(11, 'Ethan Brown', 'Casual daily news reader.', NULL),
(12, 'Blocked User', 'Account suspended due to repeated spam violations.', NULL);

-- 3. CATEGORIES (1-4 Root Groups, 5-12 Subcategories)
INSERT INTO categories (name, slug, parent_id) VALUES
('Technology', 'technology', NULL),
('Business & Economy', 'business-economy', NULL),
('Sports', 'sports', NULL),
('Science & Space', 'science-space', NULL),
('Artificial Intelligence', 'artificial-intelligence', 1),
('Cybersecurity', 'cybersecurity', 1),
('Software Engineering', 'software-engineering', 1),
('Global Markets', 'global-markets', 2),
('Startups & Venture Capital', 'startups-vc', 2),
('Football', 'football', 3),
('Formula 1', 'formula-1', 3),
('Space Exploration', 'space-exploration', 4);

-- 4. USER PREFERRED CATEGORIES
INSERT INTO user_preferred_categories (user_id, category_id) VALUES
(7, 1), (7, 5), (7, 7),
(8, 2), (8, 8), (8, 9),
(9, 3), (9, 10), (9, 11),
(10, 4), (10, 12), (10, 5),
(11, 1), (11, 3);

-- 5. SUBSCRIPTION PLANS
INSERT INTO subscription_plans (name, price, duration_days, is_active) VALUES
('Free Tier', 0.00, 3650, TRUE),
('Premium Monthly', 9.99, 30, TRUE),
('Premium Annual', 89.99, 365, TRUE),
('Legacy Student Plan', 4.99, 30, FALSE);

-- 6. SUBSCRIPTIONS
INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date) VALUES
(7, 2, 'ACTIVE', '2026-11-01 10:00:00', '2026-12-01 10:00:00'),
(8, 3, 'ACTIVE', '2026-06-15 14:30:00', '2027-06-15 14:30:00'),
(9, 2, 'EXPIRED', '2026-09-10 09:00:00', '2026-10-10 09:00:00'),
(10, 2, 'CANCELLED', '2026-10-20 12:00:00', '2026-11-20 12:00:00'),
(11, 1, 'ACTIVE', '2026-06-22 13:50:00', '2036-06-22 13:50:00');

-- 7. ARTICLES (1-12 PUBLISHED, 13-14 DRAFT; Articles 1 & 12 tailored to video demos)
INSERT INTO articles (author_id, category_id, title, slug, summary, content, is_premium, status, published_at, created_at) VALUES
(3, 5, 'AI-Driven Botanical Time-Lapse Analysis: How Vision Models Track Plant Growth', 'ai-botanical-timelapse-vision-2026',
 'Deep learning computer vision pipelines are detecting micro-changes in plant blooming cycles to optimize vertical farming yields.',
 'Modern agricultural technology relies on high-definition time-lapse imaging paired with vision-transformer models. By analyzing frame-by-frame petal expansion and cellular growth rates in real time, automated greenhouses adjust light spectrums and nutrient delivery without manual intervention...',
 FALSE, 'PUBLISHED', '2026-11-10 09:00:00', '2026-11-09 18:20:00'),

(4, 6, 'Inside the 2026 Zero-Day Supply Chain Attacks: A Forensic Breakdown', 'zero-day-supply-chain-forensics',
 'An exclusive deep dive into how attackers compromised CI/CD build pipelines and how to harden your artifacts.',
 'During a three-month investigation across 40 affected organizations, security researchers uncovered a novel persistence mechanism embedded inside container base layers. This premium report details the exact indicators of compromise (IoCs), SBOM verification steps, and sigstore policies...',
 TRUE, 'PUBLISHED', '2026-11-11 11:30:00', '2026-11-10 21:00:00'),

(3, 7, 'Clean Architecture vs. Modular Monoliths: Choosing the Right Scale in 2026', 'clean-arch-modular-monoliths',
 'Why many mid-sized engineering teams are consolidating microservices back into well-structured modular monoliths.',
 'Microservices solve organizational scaling problems, yet prematurely splitting a domain introduces distributed transaction headaches and network overhead. Here is a practical architectural checklist for structuring domain boundaries cleanly...',
 FALSE, 'PUBLISHED', '2026-11-12 14:15:00', '2026-11-12 08:45:00'),

(5, 8, 'Central Bank Rate Cuts and Sovereign Bond Yields: Q4 Global Outlook', 'central-bank-rates-q4-outlook',
 'Institutional investors are repositioning portfolios as inflation stabilizes across major G7 economies.',
 'With benchmark interest rates entering a predictable easing cycle, capital flows are rotating back into growth equities and emerging market debt. Our macro desk models three yield-curve scenarios for institutional and retail investors...',
 TRUE, 'PUBLISHED', '2026-11-13 07:45:00', '2026-11-12 22:10:00'),

(5, 9, 'European AI Infrastructure Startups Raise Record $4.2B in Seed and Series A', 'european-ai-startups-funding-2026',
 'Developer tooling, synthetic data platforms, and sovereign compute providers lead the latest venture wave.',
 'Venture capital firms in London, Munich, and Warsaw have doubled down on foundational developer infrastructure rather than thin application wrappers. Founders with deep systems engineering backgrounds are commanding top valuations...',
 FALSE, 'PUBLISHED', '2026-11-14 10:20:00', '2026-11-13 19:00:00'),

(6, 10, 'Champions League Matchday Review: Tactical Shifts That Decided the Top Clashes', 'ucl-matchday-tactical-review',
 'High-pressing traps and inverted fullbacks dominated Europe''s biggest midweek fixtures.',
 'An intense round of European football saw underdog sides punish high defensive lines through rapid vertical transitions. Breaking down the expected goals (xG) maps and midfield passing networks from Tuesday and Wednesday nights...',
 FALSE, 'PUBLISHED', '2026-11-15 08:30:00', '2026-11-14 23:50:00'),

(6, 11, 'Telemetry Deep Dive: How New Active Aero Rules Changed Cornering Speeds in F1', 'f1-active-aero-telemetry-analysis',
 'Exclusive lap-time sector comparisons reveal which constructors mastered low-drag straightline efficiency.',
 'Using corner-by-corner speed traces and energy recovery deployment charts, we analyze why two midfield teams closed the qualifying gap by four-tenths of a second on high-downforce circuits...',
 TRUE, 'PUBLISHED', '2026-11-16 13:00:00', '2026-11-16 09:10:00'),

(6, 12, 'Lunar South Pole Relay Satellites Enter Final Orbit Ahead of Rover Landing', 'lunar-relay-satellites-orbit',
 'Continuous high-bandwidth laser communications are now active for upcoming surface missions.',
 'Mission control confirmed nominal insertion burn for the three-satellite constellation orbiting the lunar south pole, eliminating communication blackouts inside permanently shadowed craters...',
 FALSE, 'PUBLISHED', '2026-11-16 17:40:00', '2026-11-16 14:00:00'),

(4, 6, 'Post-Quantum Cryptography Migration Guide for Financial Institutions', 'post-quantum-crypto-migration-guide',
 'Step-by-step roadmap for transitioning TLS endpoints and key management systems to lattice-based algorithms.',
 'Harvest-now, decrypt-later threats are forcing banks and payment processors to inventory cryptographic dependencies today. This exclusive guide covers hybrid X25519-ML-KEM deployments and HSM firmware readiness...',
 TRUE, 'PUBLISHED', '2026-11-17 09:15:00', '2026-11-16 20:30:00'),

(3, 5, 'Benchmarking Autonomous Coding Agents on Real-World Legacy Repositories', 'benchmarking-coding-agents-2026',
 'We tested five leading coding agents on multi-file refactoring, SQL optimization, and unit test generation.',
 'While single-file code completion is largely solved, multi-repository dependency resolution remains a major differentiator. Full benchmark tables, token cost metrics, and failure mode analysis inside...',
 TRUE, 'PUBLISHED', '2026-11-18 11:00:00', '2026-11-17 19:45:00'),

(5, 8, 'Semiconductor Supply Chain Diversification: New Fab Capacities Come Online', 'semiconductor-fab-capacities-2026',
 'Packaging bottlenecks ease as new automated assembly facilities begin volume production.',
 'Lead times for high-bandwidth memory and custom ASICs have dropped to 14 weeks, relieving pressure on cloud hardware providers and automotive manufacturers alike...',
 FALSE, 'PUBLISHED', '2026-11-18 16:20:00', '2026-11-18 12:10:00'),

(3, 7, 'Open-Source 3D Rendering Engines: Benchmarking Real-Time Path Tracing in Animation', 'open-source-3d-rendering-benchmarks-2026',
 'How modern GPU-accelerated open-source render pipelines cut frame generation times for independent animation studios.',
 'Rendering complex fur simulation, subsurface scattering, and dynamic foliage once required massive proprietary render farms. Using classic open-source 3D production benchmarks like Big Buck Bunny, graphics engineers demonstrate how modern denoising algorithms and compute shaders achieve cinema-grade frame rates on single workstations...',
 TRUE, 'PUBLISHED', '2026-11-19 08:00:00', '2026-11-18 21:30:00'),

(3, 7, 'Designing Resilient Event-Driven Pipelines with Apache Kafka and Outbox Pattern', 'kafka-outbox-pattern-guide',
 'Draft guide on eliminating dual-write inconsistencies in high-throughput backend services.',
 'Work in progress: covering transactional outbox tables, CDC connectors, idempotent consumers, and dead-letter queue strategies...',
 FALSE, 'DRAFT', NULL, '2026-11-19 10:15:00'),

(4, 6, 'Hardware Security Keys vs. Passkeys: Enterprise Authentication Trade-offs', 'hardware-keys-vs-passkeys-draft',
 'Draft comparative analysis of FIDO2 device-bound credentials and synced platform passkeys.',
 'Work in progress: evaluating phishing resistance, account recovery workflows, and compliance requirements...',
 TRUE, 'DRAFT', NULL, '2026-11-19 11:40:00');

-- 8. TAGS & ARTICLE_TAGS
INSERT INTO tags (name) VALUES
('AI'), ('LLM'), ('Cybersecurity'), ('Zero-Trust'), ('Architecture'),
('Cloud'), ('Macroeconomics'), ('Venture Capital'), ('Semiconductors'),
('Champions League'), ('Football Analytics'), ('Formula 1'),
('Aerodynamics'), ('Space'), ('Cryptography');

INSERT INTO article_tags (article_id, tag_id) VALUES
(1, 1), (1, 6),
(2, 3), (2, 4),
(3, 5), (3, 6),
(4, 7),
(5, 1), (5, 8),
(6, 10),
(7, 12), (7, 13),
(8, 14),
(9, 3), (9, 15),
(10, 1), (10, 2), (10, 5),
(11, 7), (11, 9),
(12, 1), (12, 5),
(13, 5), (13, 6),
(14, 3), (14, 15);

-- 9. ARTICLE MEDIA (Live Public CDN Images & Videos)
INSERT INTO article_media (article_id, media_url, media_type, caption) VALUES
(1, 'https://picsum.photos/id/1/800/450', 'IMAGE', 'Optical sensor workstation used for automated greenhouse telemetry'),
(1, 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4', 'VIDEO', 'Time-lapse blooming sequence processed by the computer vision growth-tracking model'),
(2, 'https://picsum.photos/id/60/800/450', 'IMAGE', 'Diagram of the compromised container build pipeline'),
(3, 'https://picsum.photos/id/180/800/450', 'IMAGE', 'Domain module isolation and shared kernel structure'),
(4, 'https://picsum.photos/id/1033/800/450', 'IMAGE', 'Projected 10-year sovereign bond yield trajectories'),
(5, 'https://picsum.photos/id/366/800/450', 'IMAGE', 'European AI infrastructure investment by quarter'),
(6, 'https://picsum.photos/id/1058/800/450', 'IMAGE', 'High-pressing recovery zones in midweek fixtures'),
(7, 'https://picsum.photos/id/1071/800/450', 'IMAGE', 'Throttle and speed trace comparison through Sector 2'),
(8, 'https://picsum.photos/id/903/800/450', 'IMAGE', 'Elliptical frozen orbit coverage over the Lunar South Pole'),
(9, 'https://picsum.photos/id/2/800/450', 'IMAGE', 'Hybrid TLS 1.3 key exchange sequence'),
(10, 'https://picsum.photos/id/0/800/450', 'IMAGE', 'Pass@1 resolution rates across multi-file benchmark tasks'),
(12, 'https://www.w3schools.com/html/mov_bbb.mp4', 'VIDEO', 'Open-source 3D animation benchmark testing fur dynamics, foliage, and global illumination');

-- 10. ARTICLE INTERACTIONS
INSERT INTO article_interactions (user_id, article_id, is_liked, is_bookmarked, viewed_at) VALUES
(7, 1, TRUE, TRUE, '2026-11-10 11:20:00'),
(7, 2, TRUE, TRUE, '2026-11-11 14:05:00'),
(7, 3, TRUE, FALSE, '2026-11-12 16:40:00'),
(7, 9, FALSE, TRUE, '2026-11-17 12:15:00'),
(7, 10, TRUE, TRUE, '2026-11-18 13:30:00'),
(8, 4, TRUE, TRUE, '2026-11-13 09:10:00'),
(8, 5, TRUE, FALSE, '2026-11-14 12:45:00'),
(8, 11, TRUE, TRUE, '2026-11-18 18:00:00'),
(8, 1, FALSE, TRUE, '2026-11-11 19:20:00'),
(9, 6, TRUE, FALSE, '2026-11-15 10:05:00'),
(9, 7, FALSE, TRUE, '2026-11-16 15:30:00'),
(9, 12, FALSE, FALSE, '2026-11-19 09:10:00'),
(10, 8, TRUE, TRUE, '2026-11-16 19:00:00'),
(10, 1, TRUE, FALSE, '2026-11-12 21:15:00'),
(11, 1, TRUE, FALSE, '2026-11-11 08:30:00'),
(11, 6, TRUE, TRUE, '2026-11-15 20:40:00'),
(11, 8, FALSE, FALSE, '2026-11-17 14:25:00');

-- 11. COMMENTS
INSERT INTO comments (article_id, user_id, content, created_at) VALUES
(1, 7, 'We tested a similar frame-diffing pipeline in our hydroponics lab — tracking petal opening speed accurately predicts nutrient uptake.', '2026-11-10 12:05:00'),
(1, 10, 'Would love to see a follow-up on camera calibration under variable LED grow lights.', '2026-11-12 21:30:00'),
(2, 7, 'The section on verifying image signatures in CI/CD before deployment is mandatory reading for every DevOps team.', '2026-11-11 15:10:00'),
(3, 11, 'Totally agree. Splitting into 15 microservices with a team of four nearly killed our delivery speed last year.', '2026-11-13 10:15:00'),
(4, 8, 'Clear breakdown of the 2s10s curve steepening. Looking forward to your Q1 equity sector rotation piece.', '2026-11-13 11:45:00'),
(6, 9, 'That second-half tactical adjustment on the left flank completely neutralized their build-up play.', '2026-11-15 11:20:00'),
(6, 11, 'What a comeback in the final ten minutes!', '2026-11-15 21:00:00'),
(8, 10, 'Laser optical links around the lunar south pole will be a game changer for Artemis surface telemetry.', '2026-11-16 19:25:00'),
(10, 7, 'In our experience, agents handle unit test scaffolding well, but still need strict human review on complex SQL joins.', '2026-11-18 14:10:00');

-- 12. AUTHOR SUBSCRIPTIONS
INSERT INTO author_subscriptions (subscriber_id, author_id, created_at) VALUES
(7, 3, '2026-03-05 10:00:00'),
(7, 4, '2026-03-10 14:20:00'),
(8, 5, '2026-03-20 09:30:00'),
(8, 3, '2026-04-12 16:00:00'),
(9, 6, '2026-04-18 11:15:00'),
(10, 6, '2026-05-22 18:45:00'),
(10, 3, '2026-06-01 12:30:00'),
(11, 3, '2026-07-14 15:00:00');

-- 13. NOTIFICATIONS
INSERT INTO notifications (user_id, channel, title, message, is_read, created_at) VALUES
(7, 'PUSH', 'New article from David Chen', 'David Chen published: Benchmarking Autonomous Coding Agents on Real-World Legacy Repositories', TRUE, '2026-11-18 11:01:00'),
(7, 'EMAIL', 'Your Daily Technology Digest', 'Top stories in Artificial Intelligence and Cybersecurity curated for you.', FALSE, '2026-11-19 08:00:00'),
(8, 'EMAIL', 'New Premium Report by Marcus Thorne', 'Marcus Thorne published: Central Bank Rate Cuts and Sovereign Bond Yields: Q4 Global Outlook', TRUE, '2026-11-13 07:46:00'),
(8, 'PUSH', 'Market Update: Semiconductors', 'New article in Global Markets: Semiconductor Supply Chain Diversification', FALSE, '2026-11-18 16:21:00'),
(9, 'PUSH', 'New article from Elena Rostova', 'Elena Rostova published: Champions League Matchday Review', FALSE, '2026-11-15 08:31:00'),
(10, 'EMAIL', 'Space Exploration Weekly Digest', 'Lunar South Pole Relay Satellites Enter Final Orbit Ahead of Rover Landing', TRUE, '2026-11-17 08:00:00'),
(11, 'PUSH', 'Trending in Technology', 'AI-Driven Botanical Time-Lapse Analysis is trending today.', TRUE, '2026-11-10 15:00:00');

-- 14. ADVERTISEMENTS
INSERT INTO advertisements (advertiser_name, title, banner_url, target_url, placement, category_id, impressions_count, clicks_count, is_active, start_date, end_date) VALUES
('CloudScale GPU', 'Deploy Dedicated H200 Clusters in 60 Seconds — Get $200 Free Credit', 'https://picsum.photos/id/20/728/90', 'https://example.com/promo/cloudscale-gpu', 'TOP_BANNER', 1, 18420, 612, TRUE, '2026-11-01 00:00:00', '2026-12-31 23:59:59'),
('ZeroTrust Shield', 'Automated SBOM & Container Vulnerability Scanning for DevSecOps Teams', 'https://picsum.photos/id/48/300/250', 'https://example.com/promo/zerotrust-shield', 'SIDEBAR', 6, 9350, 284, TRUE, '2026-11-05 00:00:00', '2026-12-15 23:59:59'),
('FinPulse Terminal', 'Real-Time Sovereign Yield Curves & Institutional Macro Analytics', 'https://picsum.photos/id/160/600/200', 'https://example.com/promo/finpulse', 'IN_ARTICLE', 2, 12100, 405, TRUE, '2026-11-01 00:00:00', '2026-12-20 23:59:59'),
('PitchVision Pro', 'Next-Gen Tactical Video Analysis Software for Football Academies', 'https://picsum.photos/id/1058/300/250', 'https://example.com/promo/pitchvision', 'SIDEBAR', 3, 7640, 198, TRUE, '2026-11-10 00:00:00', '2026-12-10 23:59:59'),
('Nordic Roasters', 'Specialty Single-Origin Coffee Subscription — 25% Off Your First Box', 'https://picsum.photos/id/42/728/90', 'https://example.com/promo/nordic-coffee', 'TOP_BANNER', NULL, 25890, 930, TRUE, '2026-10-15 00:00:00', '2026-12-31 23:59:59'),
('DevConf Europe 2026', 'Early Bird Tickets for Europe''s Largest Software Architecture Summit', 'https://picsum.photos/id/119/600/200', 'https://example.com/promo/devconf-2026', 'IN_ARTICLE', 7, 14200, 510, FALSE, '2026-09-01 00:00:00', '2026-10-31 23:59:59');