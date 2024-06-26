# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::InventoryUnit do
  let(:stock_location) { create(:stock_location_with_items) }
  let(:stock_item) { stock_location.stock_items.order(:id).first }

  context "#backordered_for_stock_item" do
    let(:order) { create(:order) }

    let(:shipment) do
      shipment = Spree::Shipment.new
      shipment.stock_location = stock_location
      shipment.shipping_methods << create(:shipping_method)
      shipment.order = order
      # We don't care about this in this test
      allow(shipment).to receive(:ensure_correct_adjustment)
      shipment.tap(&:save!)
    end

    let!(:unit) do
      unit = shipment.inventory_units.build
      unit.state = 'backordered'
      unit.variant_id = stock_item.variant.id
      unit.tap(&:save!)
    end

    # Regression for Spree #3066
    it "returns modifiable objects" do
      units = Spree::InventoryUnit.backordered_for_stock_item(stock_item)
      expect { units.first.save! }.not_to raise_error
    end

    it "finds inventory units from its stock location " \
       "when the unit's variant matches the stock item's variant" do
      expect(Spree::InventoryUnit.backordered_for_stock_item(stock_item)).to eq [unit]
    end

    it "does not find inventory units that don't match the stock item's variant" do
      other_variant_unit = shipment.inventory_units.build
      other_variant_unit.state = 'backordered'
      other_variant_unit.variant = create(:variant)
      other_variant_unit.save!

      expect(Spree::InventoryUnit.backordered_for_stock_item(stock_item))
        .not_to include(other_variant_unit)
    end
  end

  context "variants deleted" do
    let!(:unit) do
      Spree::InventoryUnit.create(variant: stock_item.variant)
    end

    it "can still fetch variant" do
      unit.variant.destroy
      expect(unit.reload.variant).to be_a Spree::Variant
    end
  end

  context "#finalize_units!" do
    let!(:stock_location) { create(:stock_location) }
    let(:variant) { create(:variant) }
    let(:inventory_units) {
      [
        create(:inventory_unit, variant:),
        create(:inventory_unit, variant:)
      ]
    }

    it "should create a stock movement" do
      Spree::InventoryUnit.finalize_units!(inventory_units)
      expect(inventory_units.any?(&:pending)).to be_falsy
    end
  end
end
