using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using CommerceTraining.Models.Pages;
using Mediachase.Commerce.Website.Helpers;
using Mediachase.Commerce.Orders;
using Mediachase.Commerce;
using Mediachase.Commerce.Orders.Managers;
using Mediachase.Commerce.Engine;
using CommerceTraining.Models.ViewModels;
using Mediachase.Commerce.Catalog.Objects;
using Mediachase.Commerce.Catalog;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.ServiceLocation;
using EPiServer.Commerce.Order;
using EPiServer.Commerce.Marketing;
using System;
using Castle.Core.Internal;
using EPiServer.Security;
using Mediachase.Commerce.Customers;
using Mediachase.Commerce.Security;

namespace CommerceTraining.Controllers
{
    public class CartController : PageController<CartPage>
    {
        
        private const string DefaultCartName = "Default";

        private readonly IOrderRepository _orderRepository;
        private readonly IOrderFactory _orderFactory;
        private readonly IOrderGroupCalculator _orderGroupCalculator;
        private readonly IPromotionEngine _promotionEngine;
        private readonly IContentLoader _contentLoader;
        private readonly ILineItemCalculator _lineItemCalculator;
        private readonly IInventoryProcessor _inventoryProcessor;
        private readonly ILineItemValidator _lineItemValidator;
        private readonly IPlacedPriceProcessor _placedPriceProcessor;

        public CartController(IOrderRepository orderRepository
            , IOrderFactory orderFactory
            , IOrderGroupCalculator orderGroupCalculator
            , IContentLoader contentLoader
            , ILineItemCalculator lineItemCalculator
            , IPlacedPriceProcessor placedPriceProcessor
            , IInventoryProcessor inventoryProcessor
            , ILineItemValidator lineItemValidator
            , IPromotionEngine promotionEngine)
        {
            _orderRepository = orderRepository;
            _orderFactory = orderFactory;
            _orderGroupCalculator = orderGroupCalculator;
            _contentLoader = contentLoader;
            _promotionEngine = promotionEngine;
            _lineItemCalculator = lineItemCalculator;
            _inventoryProcessor = inventoryProcessor;
            _lineItemValidator = lineItemValidator;
            _placedPriceProcessor = placedPriceProcessor;
        }
        public ActionResult Index(CartPage currentPage)
        {
            // ToDo: (lab D2)
            var cart = _orderRepository.LoadCart<ICart>(GetContactId(),DefaultCartName);

            if (cart == null)
            {
                return View("NoCart");
            }
            else
            {
                var warningMessages = ValidateCart(cart);
                if (warningMessages.IsNullOrEmpty())
                {
                    warningMessages += "No messages";
                }
                _promotionEngine.Run(cart);
                Money totaldisCount = _orderGroupCalculator.GetOrderDiscountTotal(cart, cart.Currency);
                var viewModel = new CartViewModel
                {
                    LineItems = cart.GetAllLineItems(),
                    Messages = GetDiscountMessages(cart),
                    SubTotal = _orderGroupCalculator.GetSubTotal(cart),
                    WarningMessage = warningMessages
                };
                _orderRepository.Save(cart);

                return View("Index", viewModel);
            }
            
        }

        private string GetDiscountMessages(ICart cart)
        {
            string messages = string.Empty;
            var rewardDescriptions = _promotionEngine.Run(cart).ToList();
            foreach (var rewardDescription in rewardDescriptions)
            {
                messages += rewardDescription.Promotion.Description + "   ";
            }
            return messages;
        }

        public ActionResult Checkout()
        {
            // Final steps and go to checkout
            StartPage home = _contentLoader.Get<StartPage>(ContentReference.StartPage);
            ContentReference theRef = home.Settings.checkoutPage;
            string passingValue = "Coding is fun"; // could pass something of the cart instead

            return RedirectToAction("Index", new { node = theRef, passedAlong = passingValue }); 
        }

        private string ValidateCart(ICart cart)
        {
            var validationMessages = string.Empty;

            cart.ValidateOrRemoveLineItems((item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _lineItemValidator);

            cart.UpdatePlacedPriceOrRemoveLineItems(GetContact(), (item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _placedPriceProcessor);

            // Should maybe do this during CheckOut, seems not to do a inv-request
            cart.UpdateInventoryOrRemoveLineItems((item, issue) =>
                validationMessages += CreateValidationMessages(item, issue), _inventoryProcessor);

            return validationMessages; // now this one also works
        }

        private static string CreateValidationMessages(ILineItem item, ValidationIssue issue)
        {
            return string.Format("Line item with code {0} had the validation issue {1}.", item.Code, issue);
        }

        protected static CustomerContact GetContact()
        {
            return CustomerContext.Current.GetContactById(GetContactId());
        }

        protected static Guid GetContactId()
        {
            return PrincipalInfo.CurrentPrincipal.GetContactId();
        }

    }
}