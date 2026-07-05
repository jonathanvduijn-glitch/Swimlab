import { siteInfo } from "../data/siteInfo";

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div>
          <h3>{siteInfo.bedrijfsnaam}</h3>
          <p>{siteInfo.plaats}</p>
        </div>
        <div>
          <h3>Contact</h3>
          <ul>
            <li>{siteInfo.email}</li>
            <li>{siteInfo.telefoon}</li>
            <li>{siteInfo.instagram}</li>
          </ul>
        </div>
        <div>
          <h3>Snel naar</h3>
          <ul>
            <li><a href="/voorbeelden">Shirtvoorbeelden</a></li>
            <li><a href="/offerte">Offerte aanvragen</a></li>
          </ul>
        </div>
      </div>
      <div className="container footer-note">
        © {new Date().getFullYear()} {siteInfo.bedrijfsnaam} — met de hand gemaakt, niet met de lopende band.
      </div>
    </footer>
  );
}
