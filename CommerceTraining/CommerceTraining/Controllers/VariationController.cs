using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.Mvc;
using Castle.Core.Internal;
using CommerceTraining.Models.Catalog;
using CommerceTraining.Models.Pages;
using CommerceTraining.Models.ViewModels;
using EPiServer;
using EPiServer.Commerce.Catalog;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Commerce.Order;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Globalization;
using EPiServer.Security;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;
using Mediachase.Commerce;
using Mediachase.Commerce.Customers;
using Mediachase.Commerce.Security;

namespace CommerceTraining.Controllers
{
    public class VariationController : MyControllerBase<ShirtVariation>
    {
        public IOrderRepository _orderRepository;
        public IOrderFactory _orderFactory;
        private ILineItemValidator _lineItemValidator;

        public ActionResult Index(ShirtVariation currentContent)
        {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */
            var viewModel = new ShirtVariationViewModel();

            if(currentContent.MainBody!=null)
            { 
               viewModel.MainBody = currentContent.MainBody.ToString();
            }
            viewModel.priceString = currentContent.GetDefaultPrice().UnitPrice.Amount.ToString(CultureInfo.CurrentCulture);
            if (GetDefaultAsset(currentContent) != null)
            { 
                viewModel.image = GetDefaultAsset(currentContent);
            }
            viewModel.CanBeMonogrammed = currentContent.CanBeMonogrammed;


            return View(viewModel);
        }

        public VariationController(IContentLoader contentLoader, UrlResolver urlResolver, AssetUrlResolver assetUrlResolver, ThumbnailUrlResolver thumbnailUrlResolver, IOrderRepository orderRepository, IOrderFactory orderFactory, ILineItemValidator lineItemValidator) : base(contentLoader, urlResolver, assetUrlResolver, thumbnailUrlResolver)
        {
            _orderRepository = orderRepository;
            _orderFactory = orderFactory;
            _lineItemValidator = lineItemValidator;
        }


        public ActionResult AddToCart(ShirtVariation currentContent, decimal Quantity, string Monogram)
        {
            // ToDo: (lab D1) add a LineItem to the Cart

            var cart =  _orderRepository.LoadOrCreateCart<ICart>(GetContactId(), "Default");

            var variantCode = currentContent.Code;

            // if we want to redirect
            ContentReference cartRef = _contentLoader.Get<StartPage>(ContentReference.StartPage).Settings.cartPage;
            CartPage cartPage = _contentLoader.Get<CartPage>(cartRef);
            var name = cartPage.Name;
            var lang = ContentLanguage.PreferredCulture;
            string passingValue = cart.Name;

            var yabba = cart.GetAllLineItems();
            if (yabba.Any())
            {
                foreach (var lineitem in cart.GetAllLineItems())
                {

                    if (lineitem.Code.Equals(variantCode))
                    {
                        lineitem.Quantity += Quantity;
                        lineitem.PlacedPrice = currentContent.GetDefaultPrice().UnitPrice.Amount;
                        if (currentContent.CanBeMonogrammed)
                        {
                            lineitem.Properties["Monogram"] = Monogram;
                        }
                    }
                }
                var lineItem = _orderFactory.CreateLineItem(variantCode);
                lineItem.Quantity = Quantity;
                lineItem.PlacedPrice = currentContent.GetDefaultPrice().UnitPrice.Amount;
                if (currentContent.CanBeMonogrammed)
                {
                    lineItem.Properties["Monogram"] = Monogram;
                }
                var validated = _lineItemValidator.Validate(lineItem, cart.Market, (item, issue) => { });
                if (validated)
                {
                    cart.AddLineItem(lineItem);
                }
            }
            else
            {
                var lineItem = _orderFactory.CreateLineItem(variantCode);
                lineItem.Quantity = Quantity;
                if (currentContent.CanBeMonogrammed)
                {
                    lineItem.Properties["Monogram"] = Monogram;
                }
                lineItem.PlacedPrice = currentContent.GetDefaultPrice().UnitPrice.Amount;
                var validated = _lineItemValidator.Validate(lineItem, cart.Market, (item, issue) => { });
                if (validated)
                {
                    cart.AddLineItem(lineItem);
                }

            }
            _orderRepository.Save(cart);
            
            
            // go to the cart page, if needed
            return RedirectToAction("Index", lang + "/" + name, new { passedAlong = passingValue });
        }


        //public void AddToWishList(ShirtVariant currentContent)
        //{

        //}

        protected static Guid GetContactId()
        {
            return PrincipalInfo.CurrentPrincipal.GetContactId();
        }

        protected static CustomerContact GetContact()
        {
            return CustomerContext.Current.GetContactById(GetContactId());
        }
    }
}