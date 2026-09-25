-- ============================================================
--  Family OS — مخطط قاعدة البيانات · الموجة ١
--  المرجع: 17_DATA_CONTRACTS.md
--  PostgreSQL 15+
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============ أنواع محصورة ============
CREATE TYPE member_role      AS ENUM ('OWNER','PARENT','GUARDIAN');
CREATE TYPE perm_level       AS ENUM ('OBSERVER','PARTNER','FULL');
CREATE TYPE device_mode      AS ENUM ('PARENT','CHILD_LOCKED','CHILD_PREVIEW');
-- ADR-051 (2026-09-24): السياج شكلان لا شكل واحد. نظام التشغيل لا يمنحنا إلا
-- دائرة (Android Geofence.Builder · iOS CLCircularRegion)، والاحتواء الحقيقي
-- يُحسب في محرّكنا من نقاط الموقع — فيقبل أي شكل مرسوم.
CREATE TYPE geofence_shape   AS ENUM ('CIRCLE','POLYGON');
CREATE TYPE perm_key         AS ENUM ('LOCATION_FG','LOCATION_BG','ACCESSIBILITY',
                                      'BATTERY_UNRESTRICTED','AUTOSTART','NOTIFICATIONS',
                                      'USAGE_STATS','SCREEN_TIME_IOS');
-- ADR-050 (2026-09-24): فُصل DENIED إلى حالتين، لأن السلوك يختلف بينهما:
--   DENIED_SOFT      = رفض غير نهائي ⇒ تُسمح بمعاودة واحدة عند فعل المستخدم
--   DENIED_PERMANENT = الرفض الدائم (أندرويد: بعد رفضين لا تظهر نافذة النظام) ⇒ ممنوع الطلب
--   NOT_ASKED        = لم تُطلب بعد ⇒ تُطلب في سياق الميزة مع تمهيد
-- و NOT_APPLICABLE تبقى للصلاحيات غير المنطبقة على منصّة الجهاز (ADR-045).
CREATE TYPE perm_status      AS ENUM ('NOT_ASKED','GRANTED','DENIED_SOFT',
                                      'DENIED_PERMANENT','RESTRICTED_BY_OS','NOT_APPLICABLE');
CREATE TYPE sos_status       AS ENUM ('ACTIVE','ACKNOWLEDGED','RESOLVED');
CREATE TYPE conv_kind        AS ENUM ('FAMILY','DIRECT','SUBGROUP');
CREATE TYPE ai_confidence    AS ENUM ('CONFIRMED','ANALYSIS','PRELIMINARY');

-- ============================================================
-- 🅐  الهوية والعائلة
-- ============================================================

-- ADR-003: بريد وكلمة مرور فقط — لا هاتف ولا OTP
CREATE TABLE account (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email          citext UNIQUE NOT NULL,
  password_hash  text   NOT NULL,
  display_name   text   NOT NULL,
  locale         text   NOT NULL DEFAULT 'ar',
  created_at     timestamptz NOT NULL DEFAULT now()
  -- ⛔ عمدًا: لا phone · لا AAID · لا device fingerprint
);

CREATE TABLE family (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL,
  owner_account_id uuid NOT NULL REFERENCES account(id),
  plan             text NOT NULL DEFAULT 'TRIAL',
  trial_ends_at    timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE member (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id        uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  account_id       uuid NOT NULL REFERENCES account(id),
  role             member_role NOT NULL,
  permission_level perm_level  NOT NULL DEFAULT 'PARTNER',
  invited_by       uuid REFERENCES account(id),
  joined_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (family_id, account_id),

  -- المالك دائمًا FULL
  CONSTRAINT owner_is_full
    CHECK (role <> 'OWNER' OR permission_level = 'FULL'),
  -- 20_MOTHER_PERMISSIONS: الوصي مثبَّت على OBSERVER ولا يُرقّى
  CONSTRAINT guardian_is_observer
    CHECK (role <> 'GUARDIAN' OR permission_level = 'OBSERVER')
);

-- مالك واحد لكل عائلة
CREATE UNIQUE INDEX one_owner_per_family
  ON member (family_id) WHERE role = 'OWNER';

CREATE TABLE child (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id     uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  display_name  text NOT NULL,                 -- داخل العائلة فقط
  alias         text UNIQUE NOT NULL,          -- child_a7f3 — للذكاء والسجلات
  birth_year    int,
  avatar        text NOT NULL DEFAULT 'lion',
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT alias_shape CHECK (alias ~ '^child_[a-z0-9]{4,8}$')
);
COMMENT ON COLUMN child.display_name IS
  'لا يغادر حدود العائلة — التحليلات والذكاء يستخدمان alias حصرًا';

CREATE TABLE invite (
  token             text PRIMARY KEY,
  family_id         uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  email             citext NOT NULL,
  proposed_role     member_role NOT NULL DEFAULT 'PARENT',
  proposed_level    perm_level  NOT NULL DEFAULT 'PARTNER',
  invited_by        uuid NOT NULL REFERENCES account(id),
  expires_at        timestamptz NOT NULL,
  accepted_at       timestamptz
);

CREATE TABLE pairing_token (
  token       text PRIMARY KEY,
  child_id    uuid NOT NULL REFERENCES child(id) ON DELETE CASCADE,
  expires_at  timestamptz NOT NULL,            -- ٥ دقائق
  consumed_at timestamptz                      -- استخدام واحد
);

-- ============================================================
-- 🅑  الأجهزة والأذونات
-- ============================================================

CREATE TABLE device (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id     uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  account_id    uuid REFERENCES account(id),   -- NULL لجهاز الابن
  child_id      uuid REFERENCES child(id),     -- NULL لجهاز الوالد
  mode          device_mode NOT NULL,
  platform      text NOT NULL,                 -- android | ios
  os_version    text,
  manufacturer  text,                          -- لدليل البطارية المخصّص
  model         text,
  app_version   text,
  paired_at     timestamptz NOT NULL DEFAULT now(),
  -- ⛔ عمدًا: لا imei · لا mac · لا ssid · لا aaid

  CONSTRAINT mode_owner_xor CHECK (
    (mode = 'PARENT'        AND account_id IS NOT NULL AND child_id IS NULL) OR
    (mode = 'CHILD_LOCKED'  AND child_id  IS NOT NULL AND account_id IS NULL) OR
    (mode = 'CHILD_PREVIEW' AND account_id IS NOT NULL)
  )
);

CREATE TABLE device_permission (
  device_id    uuid NOT NULL REFERENCES device(id) ON DELETE CASCADE,
  key          perm_key    NOT NULL,
  status       perm_status NOT NULL,
  checked_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (device_id, key)
);
COMMENT ON TABLE device_permission IS
  'حالة مرصودة لا مفترضة. RESTRICTED_BY_OS = وضع الحماية المتقدّمة (أندرويد ١٧)';

CREATE TABLE device_health (
  device_id        uuid PRIMARY KEY REFERENCES device(id) ON DELETE CASCADE,
  last_heartbeat   timestamptz,
  battery_level    int CHECK (battery_level BETWEEN 0 AND 100),
  score            text NOT NULL DEFAULT 'GOOD',  -- GOOD | AT_RISK | OFFLINE
  reason           text,                           -- BATTERY_OPTIMIZER | NO_NETWORK | UNINSTALLED
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- 🔐 القفل الثلاثي — كل محاولة تُخطر الأب
CREATE TABLE mode_unlock_attempt (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id     uuid NOT NULL REFERENCES device(id) ON DELETE CASCADE,
  attempted_at  timestamptz NOT NULL DEFAULT now(),
  password_ok   boolean NOT NULL,
  approved      boolean,                        -- NULL = بانتظار جهاز الأب
  locked_until  timestamptz                     -- ٣ محاولات ⇒ ٢٤ ساعة
);
CREATE INDEX ON mode_unlock_attempt (device_id, attempted_at DESC);

-- ============================================================
-- 🅒  الموقع والطوارئ
-- ============================================================

CREATE TABLE location_ping (
  id           bigserial PRIMARY KEY,
  child_id     uuid NOT NULL REFERENCES child(id) ON DELETE CASCADE,
  lat          double precision NOT NULL,
  lon          double precision NOT NULL,
  accuracy_m   real,
  battery      int,
  recorded_at  timestamptz NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON location_ping (child_id, recorded_at DESC);
COMMENT ON TABLE location_ping IS 'تُقلَّم تلقائيًا بعد ٩٠ يومًا';

-- ADR-051: الشكل حرّ. lat/lon = مركز الدائرة (CIRCLE) أو **مركز الصندوق المحيط**
-- (POLYGON) — وهو ما يُسجَّل عند النظام كدائرة محيطة. radius_m للدائرة فقط.
-- الحدّ الأدنى ١٠ م (كان ٥٠): المحرّك يحسب الاحتواء بنفسه، فحدّ النظام الأدنى
-- (١٠٠–١٥٠ م) ليس حدًّا لنا — يُطبَّق عند التسجيل عند النظام لا في التخزين.
CREATE TABLE geofence (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id   uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  child_id    uuid REFERENCES child(id),        -- NULL = كل الأبناء
  name        text NOT NULL,
  shape       geofence_shape NOT NULL DEFAULT 'CIRCLE',
  lat         double precision NOT NULL,
  lon         double precision NOT NULL,
  radius_m    int,
  icon        text NOT NULL DEFAULT 'home',
  -- ⛔ ADR-051: الارتفاع وسمٌ للعرض والتنظيم — لا يدخل في الاحتواء إطلاقًا
  altitude_m  real,
  floor_label text,
  created_by  uuid NOT NULL REFERENCES account(id),
  created_at  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT geofence_radius_by_shape CHECK (
    (shape = 'CIRCLE'  AND radius_m IS NOT NULL AND radius_m BETWEEN 10 AND 5000) OR
    (shape = 'POLYGON' AND radius_m IS NULL)
  )
);

-- ADR-051: رؤوس المضلّع. المضلّع مُغلق ضمنًا (لا تُكرَّر النقطة الأولى)، والترتيب
-- بـseq. الحدّ الأدنى ٣ رؤوس يفرضه التطبيق — شرط «عبر الصفوف» لا يُكتب في SQL.
CREATE TABLE geofence_vertex (
  geofence_id  uuid NOT NULL REFERENCES geofence(id) ON DELETE CASCADE,
  seq          smallint NOT NULL CHECK (seq >= 0),
  lat          double precision NOT NULL,
  lon          double precision NOT NULL,
  PRIMARY KEY (geofence_id, seq)
);

-- ADR-051: الجدولة هي ما يجعل النطاق «ديناميكيًا» زمانيًّا، وهي مصدر NO_SHOW.
-- غياب الصفوف = نشِط دائمًا (٢٤/٧). الدقائق من منتصف الليل (time لا يُعادل ١:١ في Drift).
-- end_minute < start_minute يعني نافذة تعبر منتصف الليل (مثل ٢٢:٠٠ → ٠٦:٠٠).
CREATE TABLE geofence_schedule (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  geofence_id  uuid NOT NULL REFERENCES geofence(id) ON DELETE CASCADE,
  weekday      smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),  -- ١ = الإثنين (ISO-8601)
  start_minute smallint NOT NULL CHECK (start_minute BETWEEN 0 AND 1439),
  end_minute   smallint NOT NULL CHECK (end_minute   BETWEEN 0 AND 1439),
  expect_by    smallint CHECK (expect_by BETWEEN 0 AND 1439),      -- وقت «عدم الوصول»
  CONSTRAINT window_not_empty CHECK (end_minute <> start_minute)
);
CREATE UNIQUE INDEX ON geofence_schedule (geofence_id, weekday, start_minute);
COMMENT ON TABLE geofence_schedule IS 'غياب الصفوف = ٢٤/٧ · expect_by يُنتج NO_SHOW';

CREATE TABLE geofence_event (
  id           bigserial PRIMARY KEY,
  geofence_id  uuid NOT NULL REFERENCES geofence(id) ON DELETE CASCADE,
  child_id     uuid NOT NULL REFERENCES child(id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('ENTER','EXIT','NO_SHOW')),
  occurred_at  timestamptz NOT NULL,
  -- ADR-051: القرار يُخزَّن مع دليله — دقّة النقطة التي بُني عليها، فلا تُتّهم
  -- المنظومة بالخطأ حين يكون الخطأ في دقّة الموقع نفسها.
  accuracy_m   real
);
CREATE INDEX ON geofence_event (geofence_id, child_id, occurred_at DESC);

-- 🚨 لا يُحذف أبدًا · لا يعتمد على اشتراك ولا صلاحية
CREATE TABLE sos_alert (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id     uuid NOT NULL REFERENCES family(id),
  child_id      uuid NOT NULL REFERENCES child(id),
  triggered_at  timestamptz NOT NULL,
  received_at   timestamptz NOT NULL DEFAULT now(),
  lat           double precision,
  lon           double precision,
  status          sos_status NOT NULL DEFAULT 'ACTIVE',
  -- ADR-051: الإقرار والإنهاء حدثان مختلفان — الإقرار يقول «رأيتُ الاستغاثة»،
  -- والإنهاء يقول «انتهت». كان العقد يحفظ الثاني فقط.
  acknowledged_by uuid REFERENCES account(id),
  acknowledged_at timestamptz,
  resolved_by     uuid REFERENCES account(id),  -- إغلاق يدوي فقط
  resolved_at     timestamptz,
  request_id      uuid UNIQUE NOT NULL          -- منع الازدواج عند إعادة الإرسال
);
CREATE INDEX ON sos_alert (family_id, status) WHERE status = 'ACTIVE';

-- ============================================================
-- 🅓  التواصل
-- ============================================================

CREATE TABLE conversation (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id    uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  kind         conv_kind NOT NULL,
  title        text,
  approved_by  uuid NOT NULL REFERENCES account(id),  -- دائرة مغلقة: الأب يعتمد
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE message (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  uuid NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
  sender_account   uuid REFERENCES account(id),
  sender_child     uuid REFERENCES child(id),
  ciphertext       bytea NOT NULL,              -- 🔒 الخادم لا يملك المفتاح
  reply_to         uuid REFERENCES message(id),
  sent_at          timestamptz NOT NULL DEFAULT now(),
  edited_at        timestamptz,                 -- S-COM-006: ١٥ دقيقة
  deleted_at       timestamptz,
  request_id       uuid UNIQUE NOT NULL,
  -- S-COM-008: تثبيت رسالة داخل المحادثة (≠ تثبيت المحادثة في القائمة)
  pinned_at        timestamptz,
  pinned_by_account uuid REFERENCES account(id),
  pinned_by_child   uuid REFERENCES child(id),
  CONSTRAINT one_sender CHECK (num_nonnulls(sender_account, sender_child) = 1),
  -- التثبيت حقيقة واحدة: وقتٌ ومُثبِّت واحد، أو لا شيء
  CONSTRAINT pin_has_pinner CHECK (
    (pinned_at IS NULL) = (num_nonnulls(pinned_by_account, pinned_by_child) = 0)
  )
);
CREATE INDEX ON message (conversation_id, sent_at DESC);
CREATE INDEX ON message (conversation_id) WHERE pinned_at IS NOT NULL;

-- S-COM-005: تأكيد القراءة — القارئ هوية واحدة في عمودين.
-- (مفتاح أساسي على أعمدة قابلة للفراغ لا يمنع التكرار: نفس القارئ يمرّ مرّتين)
CREATE TABLE message_read (
  message_id  uuid NOT NULL REFERENCES message(id) ON DELETE CASCADE,
  reader_kind text NOT NULL CHECK (reader_kind IN ('ACCOUNT','CHILD')),
  reader_key  uuid NOT NULL,
  read_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, reader_key)
);
CREATE INDEX ON message_read (reader_key, read_at DESC);

-- ADR-053: إعدادات كل محادثة — ملك القارئ لا ملك المحادثة
-- (كتم الأب للمحادثة لا يجوز أن يكتمها عند الابن)
CREATE TABLE chat_preference (
  conversation_id uuid NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
  owner_kind      text NOT NULL CHECK (owner_kind IN ('ACCOUNT','CHILD')),
  owner_key       uuid NOT NULL,
  muted_until     timestamptz,    -- NULL = بلا كتم · «دائمًا» = لحظة بعيدة حقيقية
  archived_at     timestamptz,
  pinned_at       timestamptz,
  wallpaper       text,           -- light | rose | mint | violet
  bubble_theme    text,           -- p | rose | teal
  updated_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (conversation_id, owner_key)
);

CREATE TABLE call_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id     uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  started_at    timestamptz NOT NULL,
  duration_s    int,
  kind          text NOT NULL CHECK (kind IN ('AUDIO','VIDEO')),
  outcome       text NOT NULL                  -- ANSWERED | MISSED | DECLINED
  -- ⛔ عمدًا: لا تسجيل صوت ولا فيديو
);

-- ============================================================
-- 🅔  الذكاء والتدقيق
-- ============================================================

CREATE TABLE ai_event (
  id           bigserial PRIMARY KEY,
  family_id    uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  child_alias  text NOT NULL REFERENCES child(alias),  -- 🔒 alias لا الاسم
  domain       text NOT NULL,                  -- SEC | COM | EDU | ADM
  kind         text NOT NULL,
  severity     int  NOT NULL CHECK (severity BETWEEN 1 AND 5),
  payload      jsonb NOT NULL DEFAULT '{}',    -- مقتطف لا أرشيف (S-AIC-006)
  occurred_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON ai_event (family_id, occurred_at DESC);

-- يغذّي «ختم العقل» — درجة الثقة ظاهرة للأب دائمًا
CREATE TABLE ai_suggestion (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id     uuid NOT NULL REFERENCES family(id) ON DELETE CASCADE,
  child_alias   text REFERENCES child(alias),
  headline      text NOT NULL,
  action_label  text NOT NULL,                 -- زر واحد فقط
  action_kind   text NOT NULL,
  confidence    ai_confidence NOT NULL,
  confidence_pct int CHECK (confidence_pct BETWEEN 0 AND 100),
  created_at    timestamptz NOT NULL DEFAULT now(),
  applied_at    timestamptz,
  undone_at     timestamptz,                   -- تراجع ١٠ دقائق
  dismissed_at  timestamptz
);

-- 🔒 append-only — دليلنا عند أي مراجعة
CREATE TABLE audit_log (
  id          bigserial PRIMARY KEY,
  family_id   uuid NOT NULL REFERENCES family(id),
  actor       uuid REFERENCES account(id),     -- NULL = تلقائي
  action      text NOT NULL,
  target      text,
  detail      jsonb NOT NULL DEFAULT '{}',
  occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON audit_log (family_id, occurred_at DESC);

-- فرض عدم التعديل على مستوى قاعدة البيانات
CREATE OR REPLACE FUNCTION audit_immutable() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_log غير قابل للتعديل أو الحذف';
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER audit_no_update BEFORE UPDATE OR DELETE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION audit_immutable();

-- ============================================================
--  تقليم الموقع — ٩٠ يومًا
-- ============================================================
CREATE OR REPLACE FUNCTION prune_locations() RETURNS void AS $$
  DELETE FROM location_ping WHERE recorded_at < now() - interval '90 days';
$$ LANGUAGE sql;

-- ============================================================
--  ✅ تحقّق: لا عمود يحمل معرّف جهاز محظورًا
-- ============================================================
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM information_schema.columns
   WHERE table_schema='public'
     AND lower(column_name) ~ '(imei|aaid|advertis|mac_addr|ssid|sim_serial)';
  IF bad > 0 THEN
    RAISE EXCEPTION 'انتهاك سياسة العائلات: وُجد % عمود معرّف محظور', bad;
  END IF;
END $$;

-- ============================================================
--  ملحق v6 — عقد الموجة ٢ (ADR-054 · 2026-09-24)
--  مرآة 1:1 لمخطط التخزين المحلي (Drift v6): ٣٠ جدولًا جديدًا،
--  فتصل الأسطح الثلاثة — المحلّي · العقد · الشاشة — إلى ٥٤ جدولًا.
--  المعرّفات هنا نصية شفّافة (تُشتق من request_id للتزامن) لا uuid
--  من الخادم، لأن هذه المرآة للعقد المحلّي. الفهارس و RLS في موجة
--  الخادم. و`invite` و`pairing_token` معرّفان أعلاه فلا يُعادان.
-- ============================================================

CREATE TABLE learn_assignment (
  id                  text PRIMARY KEY,
  family_id           text NOT NULL,
  child_id            text NOT NULL,
  kind                text NOT NULL,
  content_ref         text NOT NULL,        -- مفتاح ARB في الحزمة الموقّعة
  reward_minutes      integer NOT NULL DEFAULT 0,
  status              text NOT NULL,
  assigned_by_account text NOT NULL,
  due_day             text,
  request_id          text NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learn_progress (
  id               text PRIMARY KEY,
  child_id         text NOT NULL,
  content_ref      text NOT NULL,
  progress_percent integer NOT NULL DEFAULT 0,
  completed_units  integer NOT NULL DEFAULT 0,
  total_units      integer NOT NULL DEFAULT 0,
  last_seen_at     timestamptz,
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learn_session (
  id          text PRIMARY KEY,
  family_id   text NOT NULL,
  child_id    text NOT NULL,
  kind        text NOT NULL,                -- lesson · quiz · memorisation · recitation · focus · adhkar · story
  content_ref text,
  started_at  timestamptz NOT NULL DEFAULT now(),
  ended_at    timestamptz,
  minutes     integer NOT NULL DEFAULT 0,
  status      text NOT NULL,
  request_id  text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learn_result (
  id              text PRIMARY KEY,
  session_id      text NOT NULL,
  child_id        text NOT NULL,
  skill_ref       text NOT NULL,
  correct         integer NOT NULL DEFAULT 0,
  total           integer NOT NULL DEFAULT 0,
  mastery_percent integer,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learn_skill_gap (
  id              text PRIMARY KEY,
  child_id        text NOT NULL,
  skill_ref       text NOT NULL,
  missed          integer NOT NULL DEFAULT 0,
  total           integer NOT NULL DEFAULT 0,
  mastery_percent integer,
  status          text NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learn_streak (
  id           text PRIMARY KEY,
  child_id     text NOT NULL,
  kind         text NOT NULL,
  current_days integer NOT NULL DEFAULT 0,
  record_days  integer NOT NULL DEFAULT 0,
  last_day     text,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- المكتسب صفٌّ لا راية: earned_at هو الحقيقة، لا عمود boolean يبتلع التاريخ
CREATE TABLE learn_achievement (
  id         text PRIMARY KEY,
  family_id  text NOT NULL,
  child_id   text NOT NULL,
  badge_ref  text NOT NULL,
  kind       text NOT NULL,
  earned_at  timestamptz NOT NULL DEFAULT now(),
  source_ref text
);

CREATE TABLE quran_plan (
  id             text PRIMARY KEY,
  family_id      text NOT NULL,
  child_id       text NOT NULL,
  surah_ref      text NOT NULL,
  from_ayah      integer NOT NULL,
  to_ayah        integer NOT NULL,
  reciter_ref    text NOT NULL,
  reward_minutes integer NOT NULL DEFAULT 0,
  offline_ready  boolean NOT NULL DEFAULT false,
  active         boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE quran_recitation (
  id              text PRIMARY KEY,
  plan_id         text NOT NULL,
  child_id        text NOT NULL,
  day             text NOT NULL,
  kind            text NOT NULL,
  status          text NOT NULL,
  completed_ayahs integer NOT NULL DEFAULT 0,
  due_day         text,
  audio_ref       text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE quran_memorization (
  id          text PRIMARY KEY,
  child_id    text NOT NULL,
  surah_ref   text NOT NULL,
  progress    integer NOT NULL DEFAULT 0,
  extra_ayahs integer NOT NULL DEFAULT 0,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- دقائق مكتسبة كقيود، لا مجموعًا ينفصل عن أسبابه
CREATE TABLE wallet_ledger (
  id            text PRIMARY KEY,
  family_id     text NOT NULL,
  child_id      text NOT NULL,
  delta_minutes integer NOT NULL,
  reason        text NOT NULL,
  source_ref    text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE family_challenge (
  id                text PRIMARY KEY,
  family_id         text NOT NULL,
  title_ref         text NOT NULL,
  kind              text NOT NULL,
  starts_day        text NOT NULL,
  ends_day          text NOT NULL,
  active            boolean NOT NULL DEFAULT true,
  created_by_account text NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- المفتاح المركّب هو المقصود: يوم الطفل داخل التحدّي صفٌّ واحد، فلا تتكرّر العلامة
CREATE TABLE family_challenge_day (
  id           text PRIMARY KEY,
  challenge_id text NOT NULL,
  child_id     text NOT NULL,
  day_index    integer NOT NULL,
  day          text NOT NULL,
  done         boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (challenge_id, child_id, day_index)
);

CREATE TABLE tutor_thread (
  id         text PRIMARY KEY,
  child_id   text NOT NULL,
  topic_ref  text NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  status     text NOT NULL
);

CREATE TABLE tutor_turn (
  id          text PRIMARY KEY,
  thread_id   text NOT NULL,
  role        text NOT NULL,
  content_ref text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- سلّم الموافقة في status (DRAFT … APPROVED)، لا حرف واجهة محفور
CREATE TABLE content_pack (
  id                 text PRIMARY KEY,
  family_id          text NOT NULL,
  kind               text NOT NULL,
  source_ref         text NOT NULL,
  status             text NOT NULL,
  difficulty         text,
  version            integer NOT NULL DEFAULT 1,
  created_by_account text NOT NULL,
  approved_by_account text,
  approved_at        timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

-- النصّ نفسه في الحزمة الموقّعة؛ الصفّ يحفظ المرجع والترتيب
CREATE TABLE content_item (
  id           text PRIMARY KEY,
  pack_id      text NOT NULL,
  kind         text NOT NULL,
  title_ref    text NOT NULL,
  body_ref     text,
  rule_seconds integer,
  sort_order   integer NOT NULL DEFAULT 0,
  phase_locked boolean NOT NULL DEFAULT false
);

CREATE TABLE learning_path (
  id                text PRIMARY KEY,
  family_id         text NOT NULL,
  child_id          text NOT NULL,
  subject_ref       text NOT NULL,
  progress_percent  integer NOT NULL DEFAULT 0,
  completed_lessons integer NOT NULL DEFAULT 0,
  total_lessons     integer NOT NULL DEFAULT 0,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learning_path_stop (
  id              text PRIMARY KEY,
  path_id         text NOT NULL,
  title_ref       text NOT NULL,
  status          text NOT NULL,
  kind            text NOT NULL,
  mastery_percent integer,
  reward_minutes  integer NOT NULL DEFAULT 0,
  sort_order      integer NOT NULL DEFAULT 0
);

CREATE TABLE attribution_rule (
  id               text PRIMARY KEY,
  family_id        text NOT NULL,
  content_ref      text NOT NULL,
  child_id         text,
  kind             text NOT NULL,
  minutes          integer NOT NULL DEFAULT 0,
  enabled          boolean NOT NULL DEFAULT true,
  auto_added       boolean NOT NULL DEFAULT false,
  schedule_day_mask integer NOT NULL DEFAULT 0,
  assigned         boolean NOT NULL DEFAULT false
);

CREATE TABLE focus_schedule (
  id           text PRIMARY KEY,
  family_id    text NOT NULL,
  name_ref     text NOT NULL,
  child_id     text NOT NULL,
  start_minute integer NOT NULL,
  end_minute   integer NOT NULL,
  days_mask    integer NOT NULL DEFAULT 0,
  enabled      boolean NOT NULL DEFAULT true
);

CREATE TABLE focus_schedule_app (
  id          text PRIMARY KEY,
  schedule_id text NOT NULL,
  app_ref     text NOT NULL
);

-- ختمَان لا boolean واحد: الإشادة والإرسال حقيقتان مختلفتان
CREATE TABLE focus_advisor_note (
  id             text PRIMARY KEY,
  family_id      text NOT NULL,
  child_id       text NOT NULL,
  week_start     text NOT NULL,
  title_ref      text NOT NULL,
  body_ref       text NOT NULL,
  praise_sent_at timestamptz,
  reward_sent_at timestamptz
);

CREATE TABLE community_cache (
  id           text PRIMARY KEY,
  kind         text NOT NULL,
  title_ref    text NOT NULL,
  author_ref   text NOT NULL,
  rating       real NOT NULL DEFAULT 0,
  rating_count integer NOT NULL DEFAULT 0,
  trusted      boolean NOT NULL DEFAULT false,
  lessons      integer NOT NULL DEFAULT 0,
  quizzes      integer NOT NULL DEFAULT 0,
  fetched_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE task (
  id                text PRIMARY KEY,
  family_id         text NOT NULL,
  title_ref         text NOT NULL,
  assignee_child_id text,
  kind              text NOT NULL,
  reward_minutes    integer NOT NULL DEFAULT 0,
  courage_minutes   integer,
  playtime_minutes  integer,
  status            text NOT NULL,
  due_at            timestamptz,
  created_by_account text NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE task_submission (
  id                  text PRIMARY KEY,
  task_id             text NOT NULL,
  child_id            text NOT NULL,
  media_ref           text NOT NULL,
  submitted_at        timestamptz NOT NULL DEFAULT now(),
  status              text NOT NULL,
  reviewed_by_account text,
  reviewed_at         timestamptz
);

CREATE TABLE chore_distribution (
  id         text PRIMARY KEY,
  family_id  text NOT NULL,
  child_id   text NOT NULL,
  chores_ref text NOT NULL,
  note_ref   text,
  approved   boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- شبكة الشهر تُحسب من starts_at و calendar_type، فليسا عمودين
CREATE TABLE calendar_event (
  id                text PRIMARY KEY,
  family_id         text NOT NULL,
  title_ref         text NOT NULL,
  category          text NOT NULL,
  calendar_type     text NOT NULL,
  starts_at         timestamptz NOT NULL,
  place_ref         text,
  reminder_minutes  integer,
  who_ref           text,
  weekly_repeat     boolean NOT NULL DEFAULT false,
  created_by_account text NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- حالة فقط: لا بطاقة ولا إيصال ولا معرّف مشترٍ ينزل على الجهاز أبدًا
CREATE TABLE subscription_state (
  id         text PRIMARY KEY,
  family_id  text NOT NULL,
  plan_ref   text NOT NULL,
  status     text NOT NULL,
  started_at timestamptz,
  renews_at  timestamptz,
  period_end timestamptz,
  source     text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE billing_event (
  id             text PRIMARY KEY,
  family_id      text NOT NULL,
  kind           text NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  store_ref      text,
  payload_digest text
);

-- ============================================================
--  ✅ تحقّق v6: عقد الموجة ٢ لا يحمل مفتاح ARB في أي عمود
-- ============================================================
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM information_schema.columns
   WHERE table_schema='public'
     AND table_name IN (
       'learn_assignment','learn_progress','learn_session','learn_result',
       'learn_skill_gap','learn_streak','learn_achievement','quran_plan',
       'quran_recitation','quran_memorization','wallet_ledger',
       'family_challenge','family_challenge_day','tutor_thread','tutor_turn',
       'content_pack','content_item','learning_path','learning_path_stop',
       'attribution_rule','focus_schedule','focus_schedule_app',
       'focus_advisor_note','community_cache','task','task_submission',
       'chore_distribution','calendar_event','subscription_state','billing_event')
     AND (lower(column_name) LIKE '%\_key' ESCAPE '\'
          OR lower(column_name) IN ('text_ar','text_en','label'));
  IF bad > 0 THEN
    RAISE EXCEPTION 'انتهاك ADR-054: وُجد % عمود يحمل نصًّا أو مفتاحًا في العقد', bad;
  END IF;
END $$;
