import { useState } from "react";
import { NavLink } from "react-router-dom";
import { siteInfo } from "../data/siteInfo";

// Navigatielinks staan hier vast. Nieuwe pagina toevoegen aan het menu?
// Voeg een regel toe aan deze lijst en maak de bijbehorende pagina aan
// in src/pages, plus een route in App.jsx.
const links = [
  { to: "/", label: "Home" },
  { to: "/voorbeelden", label: "Voorbeelden" },
  { to: "/offerte", label: "Offerte aanvragen" },
  { to: "/over-ons", label: "Over ons" },
  { to: "/contact", label: "Contact" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="site-header">
      <div className="nav-wrap">
        <NavLink to="/" className="logo" onClick={() => setOpen(false)}>
          {siteInfo.bedrijfsnaam}
        </NavLink>

        <button
          type="button"
          className="nav-toggle"
          aria-label="Menu"
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          ☰
        </button>

        <ul className={`nav-links${open ? " open" : ""}`}>
          {links.map((link) => (
            <li key={link.to}>
              <NavLink
                to={link.to}
                end={link.to === "/"}
                onClick={() => setOpen(false)}
                className={({ isActive }) => (isActive ? "active" : undefined)}
              >
                {link.label}
              </NavLink>
            </li>
          ))}
        </ul>
      </div>
    </header>
  );
}
