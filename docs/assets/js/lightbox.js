document.addEventListener('DOMContentLoaded', () => {
  // --- Lightbox Functionality ---
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

  // Add click listeners to all images in wrappers and side-by-side blocks
  document.querySelectorAll('.img-wrapper img, .side-by-side img').forEach(img => {
    img.addEventListener('click', () => {
      lightboxImg.src = img.src;
      const caption = img.closest('.img-wrapper')?.querySelector('.caption') || 
                      img.closest('.side-by-side')?.querySelector('.caption');
      lightboxCaption.textContent = caption ? caption.textContent : '';
      overlay.classList.add('active');
    });
  });

  const closeLightbox = () => overlay.classList.remove('active');
  closeBtn.addEventListener('click', closeLightbox);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeLightbox();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeLightbox();
  });

  // --- Scroll-Spy for Side Nav ---
  const sideNavLinks = document.querySelectorAll('.side-nav a');
  const sections = Array.from(sideNavLinks).map(link => {
    const id = link.getAttribute('href').substring(1);
    return document.getElementById(id);
  }).filter(section => section !== null);

  if (sections.length > 0) {
    const observerOptions = {
      root: null,
      rootMargin: '-10% 0px -80% 0px',
      threshold: 0
    };

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          sideNavLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${entry.target.id}`) {
              link.classList.add('active');
            }
          });
        }
      });
    }, observerOptions);

    sections.forEach(section => observer.observe(section));
  }
});

