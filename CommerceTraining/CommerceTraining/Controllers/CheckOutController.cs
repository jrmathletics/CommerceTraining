using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using CommerceTraining.Models.Pages;
using Mediachase.Commerce.Orders.Dto;
using Mediachase.Commerce.Orders.Managers;
using Mediachase.Commerce;
using Mediachase.Commerce.Website.Helpers;
using Mediachase.Commerce.Orders;
using Mediachase.Commerce.Engine;
using System;
using EPiServer.Security;
using Mediachase.Commerce.Customers;
using EPiServer.ServiceLocation;
using CommerceTraining.Models.ViewModels;
using EPiServer.Commerce.Order;
using EPiServer.Commerce.Marketing;
using Mediachase.Data.Provider;

// for the extension-method
using Mediachase.Commerce.Security;
using EPiServer.Commerce.Order.Calculator;
using Mediachase.Commerce.InventoryService;
using Mediachase.Commerce.Inventory;

namespace CommerceTraining.Controllers
{
    public class CheckOutController : PageController<CheckOutPage>
    {

        private const string DefaultCart = "Default";

        private readonly IContentLoader _contentLoader; // To get the StartPage --> Settings-links
        private readonly ICurrentMarket _currentMarket; // not in fund... yet
        private readonly IOrderRepository _orderRepository;
        private readonly IOrderFactory _orderFactory;
        private readonly IPaymentProcessor _paymentProcessor;
        private readonly IPromotionEngine _promotionEngine;
        private readonly IOrderGroupCalculator _orderGroupCalculator;
        private readonly ILineItemCalculator _lineItemCalculator;
        private readonly IInventoryProcessor _inventoryProcessor;
        private readonly ILineItemValidator _lineItemValidator;
        private readonly IPlacedPriceProcessor _placedPriceProcessor;

        public CheckOutController(IContentLoader contentLoader
    , ICurrentMarket currentMarket
    , IOrderRepository orderRepository
    , IPlacedPriceProcessor placedPriceProcessor
    , IInventoryProcessor inventoryProcessor
    , ILineItemValidator lineItemValidator
    , IOrderGroupCalculator orderGroupCalculator
    , ILineItemCalculator lineItemCalculator
    , IOrderFactory orderFactory
    , IPaymentProcessor paymentProcessor
    , IPromotionEngine promotionEngine)
        {
            _contentLoader = contentLoader;
            _currentMarket = currentMarket;
            _orderRepository = orderRepository;
            _orderGroupCalculator = orderGroupCalculator;
            _orderFactory = orderFactory;
            _paymentProcessor = paymentProcessor;
            _promotionEngine = promotionEngine;
            _lineItemCalculator = lineItemCalculator;
            _inventoryProcessor = inventoryProcessor;
            _lineItemValidator = lineItemValidator;
            _placedPriceProcessor = placedPriceProcessor;
        }

        // ToDo: in the first exercise (E1) Ship & Pay
        public ActionResult Index(CheckOutPage currentPage)
        {
            // Try to load the cart

            var model = new CheckOutViewModel(currentPage)
            {
                PaymentMethods = GetPaymentMethods(),
                ShippingMethods = GetShipmentMethods(),
                ShippingRate = GetShippingRates()
            };

            return View(model);
        }


        // Exercise (E1) creation of GetPaymentMethods(), GetShipmentMethods() and GetShippingRates() goes below
        // ToDo: Get IEnumerables of Shipping and Payment methods along with ShippingRates
        public IEnumerable<PaymentMethodDto.PaymentMethodRow> GetPaymentMethods()
        {
            return new List<PaymentMethodDto.PaymentMethodRow>(
                    PaymentManager.GetPaymentMethodsByMarket(_currentMarket.GetCurrentMarket().MarketId.Value)
                        .PaymentMethod.Rows.Cast<PaymentMethodDto.PaymentMethodRow>());
        }

        public IEnumerable<ShippingMethodDto.ShippingMethodRow> GetShipmentMethods()
        {
            return new List<ShippingMethodDto.ShippingMethodRow>(
                    ShippingManager.GetShippingMethodsByMarket(_currentMarket.GetCurrentMarket().MarketId.Value,false)
                        .ShippingMethod.Rows.Cast<ShippingMethodDto.ShippingMethodRow>());
        }

        public IEnumerable<ShippingRate> GetShippingRates()
        {
            List<ShippingRate> shippingRates = new List<ShippingRate>();
            foreach (var shippingMethod in GetShipmentMethods())
            {
                shippingRates.Add(new ShippingRate(
                    shippingMethod.ShippingMethodId,
                    shippingMethod.DisplayName,
                    new Money(shippingMethod.BasePrice,shippingMethod.Currency)));
            }
            return shippingRates;
        }




        //Exercise (E2) Do CheckOut
        public ActionResult CheckOut(CheckOutViewModel model)
        {
            // ToDo: Load the cart

            var cart = _orderRepository.LoadCart<ICart>(GetContactId(), "Default");
            if (cart == null)
            {
                throw new Exception("Cart is null");
            }

            IPurchaseOrder purchaseOrder = new PurchaseOrder(GetContactId());
            OrderReference orderReference = new OrderReference(1234,"Default",cart.CustomerId,purchaseOrder.GetType());



            // ToDo: Add an OrderAddress
            var orderaddress = AddAddressToOrder(cart);
            // ToDo: Define/update Shipping
            AdjustFirstShipmentInOrder(cart, orderaddress, model.SelectedShipId);
            // ToDo: Add a Payment to the Order 
            AddPaymentToOrder(cart,model.SelectedPayId);

            // ToDo: Add a transaction scope and convert the cart to PO
            using (var scope = new Mediachase.Data.Provider.TransactionScope())
            {
                cart.ProcessPayments(_paymentProcessor,_orderGroupCalculator);
                decimal amounts = 0;
                var firstOrderForm = cart.Forms.FirstOrDefault();
                if (firstOrderForm != null)
                {
                    foreach (var payment in firstOrderForm.Payments)
                    {
                        amounts += payment.Amount;
                    }
                }
                if (amounts != cart.GetTotal(_orderGroupCalculator).Amount)
                {
                    throw new Exception("Amounts differ");
                }
                var mypurchaseorder =_orderRepository.SaveAsPurchaseOrder(cart);
                orderReference = mypurchaseorder;
                _orderRepository.Delete(cart.OrderLink);
                scope.Complete();
            }

                // ToDo: Housekeeping (Statuses for Shipping and PO, OrderNotes and save the order)
            var po =_orderRepository.Load(orderReference);
            po.OrderStatus = OrderStatus.InProgress;
            po.GetFirstShipment().OrderShipmentStatus = OrderShipmentStatus.InventoryAssigned;
            var orderNote = new OrderNote();
            orderNote.Detail = "ShipmentDetail_" + po.GetFirstShipment().ShipmentTrackingNumber;
            orderNote.LineItemId = po.GetAllLineItems().FirstOrDefault().LineItemId;
            orderNote.Title = "OrderNoteTitleHere";
            orderNote.Type = OrderNoteTypes.Custom.ToString();
            po.Notes.Add(orderNote);
            var ppp = po as PurchaseOrder;
            ppp.ExpirationDate = DateTime.Now.AddMonths(1);
            var purchaseOrder1 = _orderRepository.Save(ppp);

            
            

                // Final steps, navigate to the order confirmation page
                StartPage home = _contentLoader.Get<StartPage>(ContentReference.StartPage);
            ContentReference orderPageReference = home.Settings.orderPage;

            // the below is a dummy, change to "PO".OrderNumber when done
            string passingValue = purchaseOrder1.OrderGroupId.ToString();

            return RedirectToAction("Index", new { node = orderPageReference, passedAlong = passingValue });
        }


        // Prewritten 
        private string ValidateCart(ICart cart)
        {
            var validationMessages = string.Empty;

            cart.ValidateOrRemoveLineItems((item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _lineItemValidator);

            cart.UpdatePlacedPriceOrRemoveLineItems(GetContact(), (item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _placedPriceProcessor);

            cart.UpdateInventoryOrRemoveLineItems((item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _inventoryProcessor);

            return validationMessages; 
        }

        private static string CreateValidationMessages(ILineItem item, ValidationIssue issue)
        {
            return string.Format("Line item with code {0} had the validation issue {1}.", item.Code, issue);
        }

        private void AdjustFirstShipmentInOrder(ICart cart, IOrderAddress orderAddress, Guid selectedShip)
        {
            IShipment shipment = cart.GetFirstShipment();
            shipment.ShippingMethodId = selectedShip;
            shipment.ShippingAddress = orderAddress;
            shipment.ShipmentTrackingNumber = "ABC123";
        }

        private void AddPaymentToOrder(ICart cart, Guid selectedPaymentGuid)
        {
            var payment = _orderFactory.CreatePayment();
            payment.PaymentMethodId = selectedPaymentGuid;
            payment.PaymentMethodName = "CoursePayment";
            payment.Amount = _orderGroupCalculator.GetTotal(cart).Amount;
            cart.AddPayment(payment);
        }

        private IOrderAddress AddAddressToOrder(ICart cart)
        {
            IOrderAddress shippingAddress = null;

            if (CustomerContext.Current.CurrentContact == null)
            {
                //return cart.GetFirstShipment().ShippingAddress;
                return new OrderAddress { Name = "Mathias",
                    CountryCode = "9999",
                    CountryName = "Norway",
                    RegionCode = "9995",
                    RegionName = "Ostlandet",
                    DaytimePhoneNumber = "93219491",
                    FirstName = "Mathias",
                    LastName = "Olsen",
                    City = "Oslo"};
            }
            else
            {

            }

            return shippingAddress;
        }

        private static CustomerContact GetContact()
        {
            //Innlogget brukerinformasjon
            return CustomerContext.Current.GetContactById(GetContactId());
        }

        private static Guid GetContactId()
        {
            //Active user, kan være anon
            return PrincipalInfo.CurrentPrincipal.GetContactId();
        }
    }
}