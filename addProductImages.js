import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function addProductImages() {
  try {

    // Get all products
    const products = await prisma.product.findMany({
      include: {
        images: true
      }
    });


    const productsWithoutImages = products.filter(product => 
      product.images.length === 0
    );


    if (productsWithoutImages.length === 0) {
      return;
    }

    let successCount = 0;
    let errorCount = 0;

    for (const product of productsWithoutImages) {
      try {
        // Create placeholder image URL
        const productInitials = product.name.substring(0, 2).toUpperCase() || 'HG';
        const placeholderImageUrl = `https://via.placeholder.com/600x600/2d5e2d/ffffff?text=${productInitials}`;

        // Add image to product
        await prisma.productImage.create({
          data: {
            productId: product.id,
            imageUrl: placeholderImageUrl,
            isPrimary: true
          }
        });

        successCount++;
      } catch (error) {
        console.error(`❌ Failed to add image to ${product.name}:`, error.message);
        errorCount++;
      }
    }


  } catch (error) {
    console.error('💥 Script failed:', error);
  } finally {
    // Properly disconnect Prisma
    await prisma.$disconnect();
    process.exit(0); // Exit cleanly
  }
}

// Handle script termination
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

// Run the script
addProductImages();