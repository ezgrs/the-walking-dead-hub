-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "episodes" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(127) NOT NULL,
    "wikihref" VARCHAR(127) NOT NULL,
    "season" SMALLINT NOT NULL,
    "number" SMALLINT NOT NULL,

    CONSTRAINT "episodes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "entities" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(127) NOT NULL,
    "wikihref" VARCHAR(127) NOT NULL,

    CONSTRAINT "entities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearances" (
    "id" SERIAL NOT NULL,
    "episodeid" INTEGER NOT NULL,
    "entityid" INTEGER NOT NULL,
    "appearancetypeid" INTEGER NOT NULL,

    CONSTRAINT "appearances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearancetypes" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(127) NOT NULL,

    CONSTRAINT "appearancetypes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearancetypealiases" (
    "id" SERIAL NOT NULL,
    "refid" INTEGER NOT NULL,
    "label" VARCHAR(127) NOT NULL,

    CONSTRAINT "appearancetypealiases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearanceformtypes" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(127) NOT NULL,

    CONSTRAINT "appearanceformtypes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearanceformtypealiases" (
    "id" SERIAL NOT NULL,
    "refid" INTEGER NOT NULL,
    "label" VARCHAR(127) NOT NULL,

    CONSTRAINT "appearanceformtypealiases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appearanceforms" (
    "id" SERIAL NOT NULL,
    "appearanceid" INTEGER NOT NULL,
    "appearanceformtypeid" INTEGER NOT NULL,

    CONSTRAINT "appearanceforms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alembic_version" (
    "version_num" VARCHAR(32) NOT NULL,

    CONSTRAINT "alembic_version_pkc" PRIMARY KEY ("version_num")
);

-- CreateIndex
CREATE UNIQUE INDEX "uq_episodes_wikihref" ON "episodes"("wikihref");

-- CreateIndex
CREATE UNIQUE INDEX "uq_entities_wikihref" ON "entities"("wikihref");

-- CreateIndex
CREATE UNIQUE INDEX "uq_appearances_episodeid_entityid" ON "appearances"("episodeid", "entityid");

-- CreateIndex
CREATE INDEX "ix_appearanceforms_appearanceid" ON "appearanceforms"("appearanceid");

-- CreateIndex
CREATE UNIQUE INDEX "uq_appearanceforms_appearanceid_appearanceformtypeid" ON "appearanceforms"("appearanceid", "appearanceformtypeid");

-- AddForeignKey
ALTER TABLE "appearances" ADD CONSTRAINT "appearances_appearancetypeid_fkey" FOREIGN KEY ("appearancetypeid") REFERENCES "appearancetypes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearances" ADD CONSTRAINT "appearances_entityid_fkey" FOREIGN KEY ("entityid") REFERENCES "entities"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearances" ADD CONSTRAINT "appearances_episodeid_fkey" FOREIGN KEY ("episodeid") REFERENCES "episodes"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearancetypealiases" ADD CONSTRAINT "appearancetypealiases_refid_fkey" FOREIGN KEY ("refid") REFERENCES "appearancetypes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearanceformtypealiases" ADD CONSTRAINT "appearanceformtypealiases_refid_fkey" FOREIGN KEY ("refid") REFERENCES "appearanceformtypes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearanceforms" ADD CONSTRAINT "appearanceforms_appearanceformtypeid_fkey" FOREIGN KEY ("appearanceformtypeid") REFERENCES "appearanceformtypes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "appearanceforms" ADD CONSTRAINT "appearanceforms_appearanceid_fkey" FOREIGN KEY ("appearanceid") REFERENCES "appearances"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

