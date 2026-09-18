import { ComponentFixture, TestBed } from '@angular/core/testing';
import { StatusBadgeComponent } from './status-badge.component';

describe('StatusBadgeComponent', () => {
  let fixture: ComponentFixture<StatusBadgeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [StatusBadgeComponent] }).compileComponents();
    fixture = TestBed.createComponent(StatusBadgeComponent);
  });

  it('renders a readable picked-up label', () => {
    fixture.componentRef.setInput('status', 'PickedUp');
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Picked up');
  });

  it('renders customer delivery confirmation clearly', () => {
    fixture.componentRef.setInput('status', 'DeliveryConfirmed');
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Confirmed received');
  });
});
