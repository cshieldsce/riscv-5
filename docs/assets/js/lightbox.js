document.addEventListener('DOMContentLoaded', () => {
  // Create lightbox elements
  const overlay = document.createElement('div');
  overlay.className = 'lightbox-overlay';
  overlay.innerHTML = `
    <span class="lightbox-close">&times;</span>
    <img src="" alt="Enlarged Diagram">
    <div class="lightbox-caption"></div>
  `;
  document.body.appendChild(overlay);

  const lightboxImg = overlay.querySelector('img');
  const lightboxCaption = overlay.querySelector('.lightbox-caption');
  const closeBtn = overlay.querySelector('.lightbox-close');

  // Add click listeners to all images in wrappers
  document.querySelectorAll('.img-wrapper img').forEach(img => {
    img.addEventListener('click', () => {
      lightboxImg.src = img.src;
      const caption = img.closest('.img-wrapper').querySelector('.caption');
      lightboxCaption.textContent = caption ? caption.textContent : '';
      overlay.classList.add('active');
    });
  });

  // Close logic
  const closeLightbox = () => overlay.classList.remove('active');
  closeBtn.addEventListener('click', closeLightbox);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeLightbox();
  });

  // ESC key to close
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeLightbox();
  });
});
