-- ============================================================
-- SKRINDIAB - SUPABASE POSTGRESQL DATABASE SCHEMA
-- Telemedicine Skrining Risiko Diabetes (Algoritma Decision Tree)
-- ============================================================

-- 1. Buat Tabel Profil Pengguna (users)
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    gender TEXT,
    phone TEXT,
    birth_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Aktifkan RLS untuk tabel users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy RLS untuk users
CREATE POLICY "Allow public read users" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Allow insert/update own user profile" ON public.users
    FOR ALL USING (true) WITH CHECK (true);


-- 2. Buat Tabel Riwayat Skrining (screenings)
CREATE TABLE IF NOT EXISTS public.screenings (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_name TEXT,
    age INT,
    gender TEXT,
    weight NUMERIC,
    height NUMERIC,
    bmi NUMERIC,
    waist_circumference NUMERIC,
    physical_activity BOOLEAN DEFAULT false,
    diet_fruits_veg BOOLEAN DEFAULT false,
    hypertension_history BOOLEAN DEFAULT false,
    high_glucose_history BOOLEAN DEFAULT false,
    family_diabetes_history TEXT,
    symptoms JSONB DEFAULT '[]'::jsonb,
    risk_level TEXT NOT NULL,
    risk_score NUMERIC DEFAULT 0,
    decision_path JSONB DEFAULT '[]'::jsonb,
    recommendations JSONB DEFAULT '[]'::jsonb,
    diet_recommendations JSONB DEFAULT '[]'::jsonb,
    lifestyle_recommendations JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indeks untuk optimasi query riwayat pasien
CREATE INDEX IF NOT EXISTS idx_screenings_user_id ON public.screenings(user_id);
CREATE INDEX IF NOT EXISTS idx_screenings_created_at ON public.screenings(created_at DESC);

-- Aktifkan RLS untuk tabel screenings
ALTER TABLE public.screenings ENABLE ROW LEVEL SECURITY;

-- Policy RLS untuk screenings (Bisa dibaca dan ditulis oleh pengguna terdaftar / publik)
CREATE POLICY "Allow select screenings" ON public.screenings
    FOR SELECT USING (true);

CREATE POLICY "Allow insert/update screenings" ON public.screenings
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow delete screenings" ON public.screenings
    FOR DELETE USING (true);

-- 3. Data Contoh Pengujian (Optional Demo Data)
INSERT INTO public.screenings (
    id, user_id, user_name, age, gender, weight, height, bmi, 
    waist_circumference, physical_activity, diet_fruits_veg, 
    hypertension_history, high_glucose_history, family_diabetes_history,
    symptoms, risk_level, risk_score, decision_path, recommendations, 
    diet_recommendations, lifestyle_recommendations, created_at
) VALUES (
    'sc_sample_demo_01', 
    'guest_user_id', 
    'Pengguna Tamu', 
    52, 
    'Laki-laki', 
    78.5, 
    168.0, 
    27.8, 
    94.0, 
    false, 
    false, 
    true, 
    false, 
    'first_degree', 
    '["Sering haus berlebihan (Polidipsia)", "Sering buang air kecil di malam hari (Poliuria)"]'::jsonb, 
    'Tinggi', 
    76.0, 
    '["🌲 [Node 1 - Root] Mengevaluasi Riwayat Gula Darah Tinggi...", "├─ ➔ Riwayat Gula Darah Tinggi: TIDAK", "│  [Node 2B] Mengevaluasi Indeks Massa Tubuh (IMT: 27.8 - Obesitas)", "│  ├─ ➔ Kategori IMT: OBESITAS (>= 25.0 kg/m²)", "│  [Node 3B1] Mengevaluasi Riwayat Diabetes dalam Keluarga...", "│  │  ├─ ➔ Riwayat Keluarga Tingkat 1 (Orang Tua / Saudara Kandung: Positif)", "│  │  [Node 4A] Mengevaluasi Usia (52 thn) & Hipertensi (Ya)", "│  │  ├─ ➔ Memenuhi kriteria risiko tinggi (Usia >= 45, Hipertensi, atau Obesitas Sentral)", "│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO TINGGI"]'::jsonb, 
    '["Konsultasikan hasil skrining ini dengan dokter spesialis penyakit dalam atau klinik faskes primer terdekat.", "Lakukan tes laboratorium: Gula Darah Puasa (GDP) dan HbA1c."]'::jsonb, 
    '["Prinsip 3J: Jadwal, Jumlah, Jenis sesuai pedoman PERKENI.", "Perbanyak karbohidrat kompleks berserat tinggi dan kurangi nasi putih berlebih.", "Hindari minuman manis kemasan."]'::jsonb, 
    '["Olahraga aerobik teratur minimal 150 menit per minggu.", "Hindari perilaku sedenter atau duduk terlalu lama."]'::jsonb, 
    NOW() - INTERVAL '2 days'
) ON CONFLICT (id) DO NOTHING;
