import { Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import Voorbeelden from "./pages/Voorbeelden";
import Offerte from "./pages/Offerte";
import OverOns from "./pages/OverOns";
import Contact from "./pages/Contact";

// Nieuwe pagina toevoegen? Maak een bestand aan in src/pages, importeer het
// hierboven en voeg een <Route> toe. Vergeet niet ook de link toe te voegen
// in src/components/Navbar.jsx.
function App() {
  return (
    <>
      <Navbar />
      <main>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/voorbeelden" element={<Voorbeelden />} />
          <Route path="/offerte" element={<Offerte />} />
          <Route path="/over-ons" element={<OverOns />} />
          <Route path="/contact" element={<Contact />} />
        </Routes>
      </main>
      <Footer />
    </>
  );
}

export default App;
