-- CreateTable
CREATE TABLE "bootstrapruns" (
    "version" INTEGER NOT NULL,
    "executedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bootstrapruns_pkey" PRIMARY KEY ("version")
);
