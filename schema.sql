-- ============================================================
-- RACINES — Schéma Supabase complet
-- Copiez ce code dans : Supabase > SQL Editor > New query
-- ============================================================

-- Extensions
create extension if not exists "uuid-ossp";

-- ─── TABLE : profils membres ───────────────────────────────
create table public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  nom         text not null,
  prenom      text,
  email       text unique not null,
  organisation text,
  role        text default 'membre' check (role in ('admin','membre','observateur')),
  bio         text,
  avatar_url  text,
  localisation text,
  actif       boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ─── TABLE : messages du formulaire de contact ─────────────
create table public.contacts (
  id          uuid default uuid_generate_v4() primary key,
  nom         text not null,
  email       text not null,
  organisation text,
  message     text not null,
  statut      text default 'nouveau' check (statut in ('nouveau','lu','repondu','archive')),
  ip_address  text,
  created_at  timestamptz default now()
);

-- ─── TABLE : projets ───────────────────────────────────────
create table public.projets (
  id          uuid default uuid_generate_v4() primary key,
  titre       text not null,
  description text,
  contenu     text,
  pilier      text check (pilier in ('foresterie','gouvernance','financement','communautes')),
  statut      text default 'actif' check (statut in ('actif','termine','planifie')),
  localisation text,
  date_debut  date,
  date_fin    date,
  image_url   text,
  createur_id uuid references public.profiles(id),
  publie      boolean default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ─── TABLE : publications / actualités ─────────────────────
create table public.publications (
  id          uuid default uuid_generate_v4() primary key,
  titre       text not null,
  slug        text unique not null,
  contenu     text,
  extrait     text,
  categorie   text default 'actualite' check (categorie in ('actualite','rapport','guide','communique')),
  auteur_id   uuid references public.profiles(id),
  image_url   text,
  publie      boolean default false,
  vues        integer default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ─── TABLE : forums / discussions ──────────────────────────
create table public.forums (
  id          uuid default uuid_generate_v4() primary key,
  titre       text not null,
  description text,
  categorie   text default 'general' check (categorie in ('general','foresterie','gouvernance','financement','communautes','annonces')),
  createur_id uuid references public.profiles(id),
  epingle     boolean default false,
  ferme       boolean default false,
  created_at  timestamptz default now()
);

-- ─── TABLE : sujets de discussion ──────────────────────────
create table public.sujets (
  id          uuid default uuid_generate_v4() primary key,
  forum_id    uuid references public.forums(id) on delete cascade,
  titre       text not null,
  contenu     text not null,
  auteur_id   uuid references public.profiles(id),
  epingle     boolean default false,
  ferme       boolean default false,
  vues        integer default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ─── TABLE : messages/réponses dans les sujets ─────────────
create table public.messages (
  id          uuid default uuid_generate_v4() primary key,
  sujet_id    uuid references public.sujets(id) on delete cascade,
  auteur_id   uuid references public.profiles(id),
  contenu     text not null,
  parent_id   uuid references public.messages(id), -- pour les réponses
  modifie     boolean default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ─── TABLE : réactions aux messages ────────────────────────
create table public.reactions (
  id          uuid default uuid_generate_v4() primary key,
  message_id  uuid references public.messages(id) on delete cascade,
  auteur_id   uuid references public.profiles(id),
  emoji       text not null check (emoji in ('👍','❤️','🌱','👏','💡')),
  unique(message_id, auteur_id, emoji)
);

-- ─── TABLE : membres du réseau ──────────────────────────────
create table public.membres_reseau (
  id          uuid default uuid_generate_v4() primary key,
  profile_id  uuid references public.profiles(id),
  type        text check (type in ('individuel','organisation','partenaire')),
  expertise   text[],
  region      text,
  visible     boolean default true,
  created_at  timestamptz default now()
);

-- ─── TABLE : événements ────────────────────────────────────
create table public.evenements (
  id          uuid default uuid_generate_v4() primary key,
  titre       text not null,
  description text,
  lieu        text,
  date_debut  timestamptz not null,
  date_fin    timestamptz,
  type        text check (type in ('atelier','conference','formation','reunion','terrain')),
  lien        text,
  createur_id uuid references public.profiles(id),
  publie      boolean default false,
  created_at  timestamptz default now()
);

-- ─── TABLE : inscriptions aux événements ────────────────────
create table public.inscriptions (
  id          uuid default uuid_generate_v4() primary key,
  evenement_id uuid references public.evenements(id) on delete cascade,
  profile_id  uuid references public.profiles(id),
  statut      text default 'inscrit' check (statut in ('inscrit','confirme','annule')),
  created_at  timestamptz default now(),
  unique(evenement_id, profile_id)
);

-- ============================================================
-- TRIGGERS : updated_at automatique
-- ============================================================
create or replace function update_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger trg_profiles_updated  before update on public.profiles  for each row execute function update_updated_at();
create trigger trg_projets_updated   before update on public.projets   for each row execute function update_updated_at();
create trigger trg_pubs_updated      before update on public.publications for each row execute function update_updated_at();
create trigger trg_sujets_updated    before update on public.sujets    for each row execute function update_updated_at();
create trigger trg_messages_updated  before update on public.messages  for each row execute function update_updated_at();

-- Création automatique du profil lors de l'inscription
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nom)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'nom', split_part(new.email,'@',1)));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
alter table public.profiles        enable row level security;
alter table public.contacts        enable row level security;
alter table public.projets         enable row level security;
alter table public.publications    enable row level security;
alter table public.forums          enable row level security;
alter table public.sujets          enable row level security;
alter table public.messages        enable row level security;
alter table public.reactions       enable row level security;
alter table public.membres_reseau  enable row level security;
alter table public.evenements      enable row level security;
alter table public.inscriptions    enable row level security;

-- Helper : est-ce un admin ?
create or replace function is_admin()
returns boolean as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$ language sql security definer;

-- PROFILES
create policy "Public: voir les profils actifs"  on public.profiles for select using (actif = true);
create policy "User: modifier son profil"         on public.profiles for update using (auth.uid() = id);
create policy "Admin: tout gérer"                 on public.profiles for all using (is_admin());

-- CONTACTS (formulaire public)
create policy "Public: envoyer un message"        on public.contacts for insert with check (true);
create policy "Admin: voir et gérer les contacts" on public.contacts for all using (is_admin());

-- PROJETS
create policy "Public: voir projets publiés"      on public.projets for select using (publie = true);
create policy "Admin: tout gérer"                 on public.projets for all using (is_admin());
create policy "Createur: modifier son projet"     on public.projets for update using (auth.uid() = createur_id);

-- PUBLICATIONS
create policy "Public: voir publications publiées" on public.publications for select using (publie = true);
create policy "Admin: tout gérer"                  on public.publications for all using (is_admin());

-- FORUMS
create policy "Membres: voir les forums"          on public.forums for select using (auth.uid() is not null);
create policy "Admin: gérer les forums"           on public.forums for all using (is_admin());

-- SUJETS
create policy "Membres: voir les sujets"          on public.sujets for select using (auth.uid() is not null);
create policy "Membres: créer un sujet"           on public.sujets for insert with check (auth.uid() = auteur_id);
create policy "Auteur: modifier son sujet"        on public.sujets for update using (auth.uid() = auteur_id);
create policy "Admin: tout gérer"                 on public.sujets for all using (is_admin());

-- MESSAGES
create policy "Membres: voir les messages"        on public.messages for select using (auth.uid() is not null);
create policy "Membres: poster un message"        on public.messages for insert with check (auth.uid() = auteur_id);
create policy "Auteur: modifier son message"      on public.messages for update using (auth.uid() = auteur_id);
create policy "Admin: tout gérer"                 on public.messages for all using (is_admin());

-- REACTIONS
create policy "Membres: voir les réactions"       on public.reactions for select using (auth.uid() is not null);
create policy "Membres: réagir"                   on public.reactions for insert with check (auth.uid() = auteur_id);
create policy "Membres: supprimer sa réaction"    on public.reactions for delete using (auth.uid() = auteur_id);

-- EVENEMENTS
create policy "Public: voir événements publiés"   on public.evenements for select using (publie = true);
create policy "Admin: tout gérer"                 on public.evenements for all using (is_admin());

-- INSCRIPTIONS
create policy "User: voir ses inscriptions"       on public.inscriptions for select using (auth.uid() = profile_id);
create policy "User: s'inscrire"                  on public.inscriptions for insert with check (auth.uid() = profile_id);
create policy "User: annuler son inscription"     on public.inscriptions for update using (auth.uid() = profile_id);
create policy "Admin: tout gérer"                 on public.inscriptions for all using (is_admin());

-- ============================================================
-- DONNÉES INITIALES
-- ============================================================
insert into public.forums (titre, description, categorie, epingle) values
  ('Annonces du réseau',     'Informations officielles de RACINES',            'annonces',    true),
  ('Foresterie communautaire','Échanges sur la gestion des forêts communautaires','foresterie',  false),
  ('Gouvernance et politiques','Actualités législatives et plaidoyer',          'gouvernance', false),
  ('Financement vert',        'Opportunités de financement, REDD+, carbone',   'financement', false),
  ('Vie du réseau',           'Présentations, événements, retrouvailles',       'general',     false);
