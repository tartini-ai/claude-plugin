#!/usr/bin/env bash
# The workspace of this case: a small static flower shop site, with the GitHub remote the eval's
# mocks know (flower-shop-demo/storefront), committed on main and checked out on a work branch.
# claude plugin eval runs it only with --scaffold. Every case has its own identical copy, because a
# case's scaffold_script has to be in the case's own directory.
set -euo pipefail

git init -q -b main
git remote add origin https://github.com/flower-shop-demo/storefront.git

mkdir -p src
cat > index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Petal and Stem</title>
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-PS4TEST123"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag() { dataLayer.push(arguments); }
    gtag('js', new Date());
    gtag('config', 'G-PS4TEST123');
  </script>
  <script src="/tartini-autocapture.js" defer></script>
  <script src="/src/track.js"></script>
</head>
<body>
  <header>
    <a href="/shop.html">Shop</a>
    <button id="signup" type="button">Sign up</button>
  </header>
  <main>
    <a class="cta" href="/shop.html">Shop spring bouquets</a>
    <a href="/call.html">Book a florist call</a>
    <a href="/specials.html">Weekly specials</a>
  </main>
  <footer>
    <form id="newsletter">
      <input type="email" name="email" autocomplete="email">
      <button type="submit">Subscribe</button>
    </form>
    <a href="/contact.html">Contact</a>
  </footer>
  <script src="/src/site.js"></script>
</body>
</html>
HTML

cat > shop.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Shop, Petal and Stem</title>
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-PS4TEST123"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag() { dataLayer.push(arguments); }
    gtag('js', new Date());
    gtag('config', 'G-PS4TEST123');
  </script>
  <script src="/tartini-autocapture.js" defer></script>
  <script src="/src/track.js"></script>
</head>
<body>
  <button class="add" data-item="tulips" data-price="24">Add tulips</button>
  <button class="add" data-item="roses" data-price="39">Add roses</button>
  <script src="/src/cart.js"></script>
</body>
</html>
HTML

cat > src/track.js <<'JS'
function trackEvent(name, params) {
  if (typeof window.gtag === 'function') window.gtag('event', name, params);
}
JS

cat > src/site.js <<'JS'
document.getElementById('signup').addEventListener('click', function () {
  document.body.classList.add('signup-open');
});
document.getElementById('newsletter').addEventListener('submit', function () {
  trackEvent('newsletter_sign_up', { form_location: 'footer' });
});
JS

cat > src/cart.js <<'JS'
document.querySelectorAll('button.add').forEach(function (button) {
  button.addEventListener('click', function () {
    trackEvent('add_to_cart', { item_id: button.dataset.item, value: Number(button.dataset.price), currency: 'USD' });
  });
});
JS

cat > tartini-autocapture.js <<'JS'
// Stand-in for the Tartini Autocapture component, for this plugin's evals only.
JS

git add -A
git -c user.name=eval -c user.email=eval@example.com commit -q -m "Petal and Stem storefront"
git switch -q -c signup-tracking
