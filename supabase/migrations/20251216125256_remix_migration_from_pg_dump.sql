CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog";
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";
--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



--
-- Name: subscription_tier; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_tier AS ENUM (
    'free',
    'pro',
    'business'
);


--
-- Name: get_user_tier(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_tier(p_user_id uuid) RETURNS public.subscription_tier
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT tier FROM public.subscriptions WHERE user_id = p_user_id;
$$;


--
-- Name: handle_new_user_streak(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user_streak() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.user_streaks (user_id, current_streak, longest_streak)
  VALUES (NEW.id, 0, 0);
  RETURN NEW;
END;
$$;


--
-- Name: handle_new_user_subscription(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user_subscription() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.subscriptions (user_id, tier, trial_started_at, trial_ends_at, is_trial_active)
  VALUES (NEW.id, 'free', now(), now() + INTERVAL '14 days', true);
  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

--
-- Name: contact_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    contacted_at timestamp with time zone DEFAULT now() NOT NULL,
    contact_name text NOT NULL,
    label text,
    notes text,
    cadence text,
    reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    google_id text,
    name text NOT NULL,
    phone text,
    email text,
    photo text,
    labels text[] DEFAULT '{}'::text[],
    notes text DEFAULT ''::text,
    cadence text DEFAULT 'monthly'::text,
    last_contacted timestamp with time zone,
    next_due timestamp with time zone DEFAULT now(),
    ai_draft text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    linkedin_url text,
    conversation_context text,
    follow_up_override timestamp with time zone,
    is_hidden boolean DEFAULT false NOT NULL,
    x_url text,
    youtube_url text,
    birthday_month integer,
    birthday_day integer,
    birthday_year integer,
    instagram_url text,
    tiktok_url text,
    facebook_url text,
    github_url text,
    threads_url text,
    snapchat_url text,
    pinterest_url text,
    reddit_url text,
    discord_url text,
    twitch_url text,
    whatsapp_url text,
    telegram_url text,
    CONSTRAINT contacts_birthday_day_check CHECK (((birthday_day >= 1) AND (birthday_day <= 31))),
    CONSTRAINT contacts_birthday_month_check CHECK (((birthday_month >= 1) AND (birthday_month <= 12)))
);


--
-- Name: label_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    label_name text NOT NULL,
    description text,
    cadence_days integer DEFAULT 30 NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    tier public.subscription_tier DEFAULT 'free'::public.subscription_tier NOT NULL,
    trial_started_at timestamp with time zone DEFAULT now(),
    trial_ends_at timestamp with time zone DEFAULT (now() + '14 days'::interval),
    is_trial_active boolean DEFAULT true NOT NULL,
    stripe_customer_id text,
    stripe_subscription_id text,
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    cancel_at_period_end boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_streaks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_streaks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    current_streak integer DEFAULT 0 NOT NULL,
    longest_streak integer DEFAULT 0 NOT NULL,
    last_completion_date date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contact_history contact_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_history
    ADD CONSTRAINT contact_history_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_user_id_google_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_user_id_google_id_key UNIQUE (user_id, google_id);


--
-- Name: label_settings label_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_settings
    ADD CONSTRAINT label_settings_pkey PRIMARY KEY (id);


--
-- Name: label_settings label_settings_user_id_label_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_settings
    ADD CONSTRAINT label_settings_user_id_label_name_key UNIQUE (user_id, label_name);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_key UNIQUE (user_id);


--
-- Name: user_streaks user_streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_streaks
    ADD CONSTRAINT user_streaks_pkey PRIMARY KEY (id);


--
-- Name: user_streaks user_streaks_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_streaks
    ADD CONSTRAINT user_streaks_user_id_key UNIQUE (user_id);


--
-- Name: contacts update_contacts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON public.contacts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: label_settings update_label_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_label_settings_updated_at BEFORE UPDATE ON public.label_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: subscriptions update_subscriptions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_streaks update_user_streaks_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_streaks_updated_at BEFORE UPDATE ON public.user_streaks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: contact_history contact_history_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_history
    ADD CONSTRAINT contact_history_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_history contact_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_history
    ADD CONSTRAINT contact_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_streaks user_streaks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_streaks
    ADD CONSTRAINT user_streaks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions Service can insert subscriptions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service can insert subscriptions" ON public.subscriptions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: contacts Users can create their own contacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own contacts" ON public.contacts FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: label_settings Users can create their own label settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own label settings" ON public.label_settings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: contact_history Users can delete their own contact history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own contact history" ON public.contact_history FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: contacts Users can delete their own contacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own contacts" ON public.contacts FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: label_settings Users can delete their own label settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own label settings" ON public.label_settings FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: contact_history Users can insert their own contact history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own contact history" ON public.contact_history FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_streaks Users can insert their own streak; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own streak" ON public.user_streaks FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: contacts Users can update their own contacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own contacts" ON public.contacts FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: label_settings Users can update their own label settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own label settings" ON public.label_settings FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_streaks Users can update their own streak; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own streak" ON public.user_streaks FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: subscriptions Users can update their own subscription; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own subscription" ON public.subscriptions FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: contact_history Users can view their own contact history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own contact history" ON public.contact_history FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: contacts Users can view their own contacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own contacts" ON public.contacts FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: label_settings Users can view their own label settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own label settings" ON public.label_settings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_streaks Users can view their own streak; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own streak" ON public.user_streaks FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: subscriptions Users can view their own subscription; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own subscription" ON public.subscriptions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: contact_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.contact_history ENABLE ROW LEVEL SECURITY;

--
-- Name: contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: label_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.label_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_streaks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--


