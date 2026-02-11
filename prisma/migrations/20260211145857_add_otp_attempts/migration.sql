/*
  Warnings:

  - You are about to drop the column `phonepeMerchantTransactionId` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `phonepePaymentInstrumentType` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `phonepeResponseCode` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `phonepeResponseMessage` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `phonepeTransactionId` on the `orders` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[customDesignId]` on the table `order_items` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[razorpayOrderId]` on the table `orders` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[razorpayPaymentId]` on the table `orders` will be added. If there are existing duplicate values, this will fail.
  - Made the column `name` on table `categories` required. This step will fail if there are existing NULL values in that column.

*/
-- CreateEnum
CREATE TYPE "PriceType" AS ENUM ('PERCENTAGE', 'FIXED_AMOUNT');

-- CreateEnum
CREATE TYPE "DesignStatus" AS ENUM ('DRAFT', 'SAVED', 'ORDERED', 'ARCHIVED');

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_userId_fkey";

-- DropIndex
DROP INDEX "orders_phonepeMerchantTransactionId_key";

-- DropIndex
DROP INDEX "orders_phonepeTransactionId_key";

-- DropIndex
DROP INDEX "orders_trackingNumber_key";

-- AlterTable
ALTER TABLE "categories" ALTER COLUMN "name" SET NOT NULL;

-- AlterTable
ALTER TABLE "coupons" ADD COLUMN     "totalDiscounts" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "home_sliders" ALTER COLUMN "bgImage" DROP NOT NULL,
ALTER COLUMN "image" DROP NOT NULL;

-- AlterTable
ALTER TABLE "order_items" ADD COLUMN     "customDesignId" TEXT,
ADD COLUMN     "customizationPrice" DOUBLE PRECISION DEFAULT 0;

-- AlterTable
ALTER TABLE "orders" DROP COLUMN "phonepeMerchantTransactionId",
DROP COLUMN "phonepePaymentInstrumentType",
DROP COLUMN "phonepeResponseCode",
DROP COLUMN "phonepeResponseMessage",
DROP COLUMN "phonepeTransactionId",
ADD COLUMN     "courierInstructions" TEXT,
ADD COLUMN     "preferredCourier" TEXT,
ADD COLUMN     "razorpayOrderId" TEXT,
ADD COLUMN     "razorpayPaymentId" TEXT,
ADD COLUMN     "razorpaySignature" TEXT,
ALTER COLUMN "userId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "products" ADD COLUMN     "baseCustomizationPrice" DOUBLE PRECISION DEFAULT 0,
ADD COLUMN     "isCustomizable" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "subcategories" ADD COLUMN     "sizeImage" TEXT,
ADD COLUMN     "sizeImagePublicId" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "otpAttempts" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "subcategory_quantity_prices" (
    "id" TEXT NOT NULL,
    "subcategoryId" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "priceType" "PriceType" NOT NULL DEFAULT 'PERCENTAGE',
    "value" DOUBLE PRECISION NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subcategory_quantity_prices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_custom_images" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "imageKey" TEXT NOT NULL,
    "filename" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_custom_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "custom_designs" (
    "id" TEXT NOT NULL,
    "customizationId" TEXT NOT NULL,
    "userId" TEXT,
    "sessionId" TEXT,
    "designData" JSONB NOT NULL,
    "previewImage" TEXT NOT NULL,
    "thumbnailImage" TEXT NOT NULL,
    "status" "DesignStatus" NOT NULL DEFAULT 'DRAFT',
    "orderItemId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "custom_designs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_customizations" (
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "basePrice" DOUBLE PRECISION NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "maxTextLength" INTEGER NOT NULL DEFAULT 100,
    "maxImages" INTEGER NOT NULL DEFAULT 5,
    "allowedFonts" TEXT[],
    "allowedColors" TEXT[],

    CONSTRAINT "product_customizations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "subcategory_quantity_prices_subcategoryId_quantity_key" ON "subcategory_quantity_prices"("subcategoryId", "quantity");

-- CreateIndex
CREATE INDEX "order_custom_images_orderId_idx" ON "order_custom_images"("orderId");

-- CreateIndex
CREATE UNIQUE INDEX "custom_designs_orderItemId_key" ON "custom_designs"("orderItemId");

-- CreateIndex
CREATE UNIQUE INDEX "order_items_customDesignId_key" ON "order_items"("customDesignId");

-- CreateIndex
CREATE UNIQUE INDEX "orders_razorpayOrderId_key" ON "orders"("razorpayOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "orders_razorpayPaymentId_key" ON "orders"("razorpayPaymentId");

-- AddForeignKey
ALTER TABLE "subcategory_quantity_prices" ADD CONSTRAINT "subcategory_quantity_prices_subcategoryId_fkey" FOREIGN KEY ("subcategoryId") REFERENCES "subcategories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_custom_images" ADD CONSTRAINT "order_custom_images_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_customDesignId_fkey" FOREIGN KEY ("customDesignId") REFERENCES "custom_designs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "custom_designs" ADD CONSTRAINT "custom_designs_customizationId_fkey" FOREIGN KEY ("customizationId") REFERENCES "product_customizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "custom_designs" ADD CONSTRAINT "custom_designs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_customizations" ADD CONSTRAINT "product_customizations_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
