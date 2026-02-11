document.addEventListener('DOMContentLoaded', () => {
  // Select all images inside .img-wrapper
  const images = document.querySelectorAll('.img-wrapper img');

  // Create the lightbox overlay element once
  const overlay = document.createElement('div');
  overlay.className = 'lightbox-overlay';
  
  // Create the image element inside the overlay
  const overlayImg = document.createElement('img');
  overlay.appendChild(overlayImg);

  // Add caption text container
  const overlayCaption = document.createElement('div');
  overlayCaption.className = 'lightbox-caption';
  overlay.appendChild(overlayCaption);

  // Close button
  const closeBtn = document.createElement('span');
  closeBtn.className = 'lightbox-close';
  closeBtn.innerHTML = '&times;';
  overlay.appendChild(closeBtn);

  document.body.appendChild(overlay);

  // Function to open lightbox
  function openLightbox(src, alt, captionText) {
    overlayImg.src = src;
    overlayImg.alt = alt;
    overlayCaption.textContent = captionText || alt; // Use caption if available, else alt
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden'; // Prevent scrolling background
  }

  // Function to close lightbox
  function closeLightbox() {
    overlay.classList.remove('active');
    document.body.style.overflow = ''; // Restore scrolling
  }

  // Add click event to images
  images.forEach(img => {
    img.addEventListener('click', () => {
      // Find the caption if it exists (sibling .caption span)
      const caption = img.nextElementSibling && img.nextElementSibling.classList.contains('caption') 
                      ? img.nextElementSibling.textContent 
                      : '';
      openLightbox(img.src, img.alt, caption);
    });
  });

  // Close on click overlay or close button
  overlay.addEventListener('click', (e) => {
    if (e.target !== overlayImg && e.target !== overlayCaption) {
      closeLightbox();
    }
  });

  // Close on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && overlay.classList.contains('active')) {
      closeLightbox();
    }
  });
});
