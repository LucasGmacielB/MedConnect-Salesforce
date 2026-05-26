import { createElement } from "@lwc/engine-dom";
import SpeakerTile from "c/speakerTile";

describe("c-speaker-tile", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders empty state before record data is loaded", () => {
    const element = createElement("c-speaker-tile", {
      is: SpeakerTile
    });

    document.body.appendChild(element);

    expect(element.shadowRoot.textContent).toContain("No speaker selected.");
  });
});
